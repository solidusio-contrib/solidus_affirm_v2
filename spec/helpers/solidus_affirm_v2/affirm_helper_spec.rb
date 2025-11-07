# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolidusAffirmV2::AffirmHelper do
  describe "#affirm_js_setup" do
    subject(:affirm_js_setup) do
      helper.affirm_js_setup(
        SolidusAffirmV2::PaymentMethod.first.preferred_public_api_key,
        SolidusAffirmV2::PaymentMethod.first.preferred_javascript_url
      )
    end

    before do
      create(:affirm_v2_payment_method)
    end

    it "returns the public_api_key" do
      expect(affirm_js_setup).to include("public_api_key: \"public000\"")
    end

    it "returns the Affirm.js component" do
      expect(affirm_js_setup).to include("script: \"https://cdn1-sandbox.affirm.com/js/v2/affirm.js\"")
    end
  end

  describe "#affirm_payload_json" do
    before { allow(SolidusAffirmV2::Config.checkout_payload_serializer).to receive(:new) }

    let(:shipping_address) { create(:ship_address, name: "John's Do", zipcode: "52106-9133") }
    let(:order) do
      create(:order_with_line_items, ship_address: shipping_address)
    end
    let(:payment_method) { create(:affirm_v2_payment_method) }
    let(:metadata) { {} }

    it "calls the configured payload serializer" do
      helper.affirm_payload_json(order, payment_method, metadata)
      expect(SolidusAffirmV2::Config.checkout_payload_serializer).to have_received(:new)
    end
  end
end
