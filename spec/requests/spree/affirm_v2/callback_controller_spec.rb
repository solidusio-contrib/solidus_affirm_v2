require "spec_helper"
require "affirm"

RSpec.describe Spree::AffirmV2::CallbackController do
  let(:order) { create(:order_with_totals) }
  let(:checkout_token) { "FOOBAR123" }
  let(:payment_method) { create(:affirm_v2_payment_method) }

  describe "POST confirm" do
    subject { post "/affirm_v2/confirm", params: }

    context "when the order_id is not valid" do
      let(:params) {
        {
            checkout_token: checkout_token,
            payment_method_id: payment_method.id,
            order_id: nil,
            use_route: :spree
          }
      }

      it "raises an AR RecordNotFound" do
        expect { subject }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the checkout_token is missing" do
      let(:params) {
        {
          checkout_token: nil,
          payment_method_id: payment_method.id,
          order_id: order.id,
          use_route: :spree
        }
      }

      it "redirects to the order current checkout state path" do
        subject
        expect(response).to redirect_to("/checkout/cart")
      end
    end

    context "when the order is already completed" do
      let(:order) { create(:completed_order_with_totals) }
      let(:params) {
        {
          checkout_token: checkout_token,
          payment_method_id: payment_method.id,
          order_id: order.id,
          use_route: :spree
        }
      }

      it "redirects to the order detail page" do
        subject
        expect(response).to redirect_to("/orders/#{order.number}")
      end
    end

    context "with valid data" do
      let(:order) { create(:order_with_totals, state: "payment") }
      let(:affirm_payment_source) { create(:affirm_v2_transaction) }
      let(:checkout_token) { "TKLKJ71GOP9YSASU" }
      let(:transaction_id) { "N330-Z6D4" }
      let(:provider_id) { 1 }
      let!(:affirm_checkout_response) { Affirm::Struct::Transaction.new({id: transaction_id, checkout_id: checkout_token, amount: 42_499, order_id: order.id, provider_id: provider_id}) }

      before do
        allow_any_instance_of(Affirm::Client).to receive(:read_transaction).with(checkout_token).and_return(affirm_checkout_response)
      end

      it "creates a payment" do
        expect {
          subject
        }.to change { order.payments.count }.from(0).to(1)
      end

      it "creates a payment with the right amount" do
        subject
        expect(order.payments.last.amount).to eq BigDecimal("424.99")
      end

      it "creates a SolidusAffirmV2::Transaction" do
        expect {
          subject
        }.to change { SolidusAffirmV2::Transaction.count }.by(1)
      end

      it "redirect to the confirm page" do
        subject
        expect(response).to redirect_to("/checkout/confirm")
      end
    end
  end

  describe "GET cancel" do
    subject {
        get "/affirm_v2/cancel", params: {
          payment_method_id: payment_method.id,
          order_id: order.id,
          use_route: :spree
        }
    }

    context "with an order_id present" do
      it "redirects to the current order checkout state" do
        subject
        expect(response).to redirect_to("/checkout/cart")
      end
    end
  end
end
