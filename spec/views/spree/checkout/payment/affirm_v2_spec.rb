require "spec_helper"

RSpec.describe "payment/affirm_v2" do # rubocop:disable RSpec/DescribeClass
  let(:payment_method) { create(:affirm_v2_payment_method) }
  let(:address) { create(:address, name: "John's D'o", zipcode: "58451") }
  let(:order) { create(:order_with_totals, shipping_address: address) }

  before do
    allow(view).to receive_messages current_order: order
    allow(view).to receive_messages payment_method: payment_method
  end

  it "renders valid json in html5 data attribute" do
    render partial: "spree/checkout/payment/affirm_v2"
    rendered_partial = Nokogiri::HTML.fragment(rendered)
    affirm_data_attribute = rendered_partial.css("div#affirm_v2_checkout_payload")[0]["data-affirm"]
    json = JSON.parse(affirm_data_attribute)
    expect(json["shipping"]["name"]).to eql({"first" => "John's", "last" => "D'o"})
  end
end
