# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolidusAffirmV2::CheckoutPayloadSerializer do
  subject(:serialized_checkout_payload_json) { JSON.parse(serializer.to_json) }

  let(:affirm_checkout_payload) { SolidusAffirmV2::CheckoutPayload.new(order, config, metadata) }
  let(:serializer) { described_class.new(affirm_checkout_payload, root: false) }
  let(:line_item_attributes) do
    [
      {product: create(:product, name: "awesome product", sku: "P1", leasable: true)},
      {product: create(:product, name: "amazing stuff", sku: "P2")}
    ]
  end
  let(:shipping_address) { create(:ship_address, name: "John Do", zipcode: "52106-9133") }
  let(:billing_address) { create(:bill_address, name: "John Do", zipcode: "58451") }

  let(:order) do
    create(:order_with_line_items,
      line_items_count: 2,
      line_items_attributes: line_item_attributes,
      ship_address: shipping_address,
      billing_address: billing_address)
  end
  let(:config) do
    {
      confirmation_url: "https://merchantsite.com/confirm",
      cancel_url: "https://merchantsite.com/cancel",
      exchange_lease_enabled: SolidusAffirmV2::Config.exchange_lease_enabled
    }
  end
  let(:metadata) { {} }

  it "wil have a 'merchant' object" do
    merchant_json = {
      "user_confirmation_url" => "https://merchantsite.com/confirm",
      "user_cancel_url" => "https://merchantsite.com/cancel",
      "exchange_lease_enabled" => false
    }
    expect(serialized_checkout_payload_json["merchant"]).to eql merchant_json
  end

  it "will have a 'shipping' object" do
    shipping_json = {
      "name" => {"first" => "John", "last" => "Do"},
      "address" => {
        "line1" => "A Different Road",
        "line2" => "Northwest",
        "city" => "Herndon",
        "state" => "AL",
        "zipcode" => "52106-9133",
        "country" => "USA"
      }
    }
    expect(serialized_checkout_payload_json["shipping"]).to eql shipping_json
  end

  it "will have a 'billing' object" do
    billing_json = {
      "name" => {"first" => "John", "last" => "Do"},
      "address" => {
        "line1" => "PO Box 1337",
        "line2" => "Northwest",
        "city" => "Herndon",
        "state" => "AL",
        "zipcode" => "58451",
        "country" => "USA"
      }
    }
    expect(serialized_checkout_payload_json["billing"]).to eql billing_json
  end

  it "will have an 'order_id'" do
    expect(serialized_checkout_payload_json["order_id"]).to eql order.number
  end

  it "will have a 'shipping_amount'" do
    expect(serialized_checkout_payload_json["shipping_amount"]).to be 10_000
  end

  it "will have a 'tax_amount'" do
    expect(serialized_checkout_payload_json["tax_amount"]).to be 0
  end

  it "will have a 'total'" do
    expect(serialized_checkout_payload_json["total"]).to be 12_000
  end

  describe "merchant object" do
    context "without an optional external name attribute" do
      it "will not expose a name key" do
        expect(serialized_checkout_payload_json["merchant"]["name"]).to be_nil
      end
    end

    context "with the optional external name attribute present" do
      before do
        config[:name] = "Your Customer-Facing Merchant Name"
      end

      it "will expose the name serialized_checkout_payload_json key" do
        expect(serialized_checkout_payload_json["merchant"]["name"]).to eql "Your Customer-Facing Merchant Name"
      end
    end
  end

  describe "items object" do
    let(:items_json) do
      [
        {
          "display_name" => "awesome product",
          "sku" => "P1",
          "unit_price" => 1000,
          "qty" => 1,
          "item_image_url" => nil,
          "item_url" => "http://shop.localhost:3000/products/awesome-product",
          "leasable" => true
        },
        {
          "display_name" => "amazing stuff",
          "sku" => "P2",
          "unit_price" => 1000,
          "qty" => 1,
          "item_image_url" => nil,
          "item_url" => "http://shop.localhost:3000/products/amazing-stuff",
          "leasable" => false
        }
      ]
    end

    it "returns an array with the serialized line items" do
      expect(serialized_checkout_payload_json["items"]).to eql items_json
    end
  end

  describe "discounts" do
    context "with an order without any promotions" do
      it "will not render a discounts key" do
        expect(serialized_checkout_payload_json["discounts"]).to be_nil
      end
    end

    context "with an order with promotions" do
      before do
        allow(order).to receive(:promo_total).and_return(BigDecimal("100.00"))
      end

      it "will aggregate the promotions into the discounts key" do
        expect(serialized_checkout_payload_json["discounts"]).not_to be_empty
      end

      it "will have a discount_amount" do
        expect(serialized_checkout_payload_json["discounts"]["promotion_total"]["discount_amount"]).to be 10_000
      end

      it "will set the discount_display_name" do
        expect(serialized_checkout_payload_json["discounts"]["promotion_total"]["discount_display_name"]).to eql "Total promotion discount" # rubocop:disable Layout/LineLength
      end
    end
  end

  describe "metadata" do
    let(:default_meta) do
      {
        "platform_affirm" => "Solidus::AffirmV2 #{SolidusAffirmV2::VERSION}",
        "platform_type" => "Solidus",
        "platform_version" => Spree.solidus_version
      }
    end

    context "when empty" do
      it "will render the platform keys only" do
        expect(serialized_checkout_payload_json["metadata"]).to eql(default_meta)
      end
    end

    context "with any hash" do
      let(:metadata) { {foo: "bar"} }

      it "will expose that hash directly at the metadata key" do
        expect(serialized_checkout_payload_json["metadata"]).to eql(default_meta.merge({"foo" => "bar"}))
      end
    end
  end

  context "with apostrophes in name" do
    let(:shipping_address) { create(:ship_address, name: "John's Do", zipcode: "52106-9133") }

    it "renders a valid JSON" do
      shipping_name_json = {"first" => "John's", "last" => "Do"}
      expect(serialized_checkout_payload_json["shipping"]["name"]).to eql shipping_name_json
    end
  end
end
