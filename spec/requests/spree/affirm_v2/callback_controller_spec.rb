require 'spec_helper'
require 'affirm'

RSpec.describe Spree::AffirmV2::CallbackController do
  let(:order) { create(:order_with_totals) }
  let(:checkout_token) { "FOOBAR123" }
  let(:payment_method) { create(:affirm_v2_payment_method) }

  describe 'POST confirm' do
    context 'when the order_id is not valid' do
      it "will raise an AR RecordNotFound" do
        expect {
          post '/affirm_v2/confirm', params: {
            checkout_token: checkout_token,
            payment_method_id: payment_method.id,
            order_id: nil,
            use_route: :spree
          }
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the checkout_token is missing' do
      it "will redirect to the order current checkout state path" do
        post '/affirm_v2/confirm', params: {
          checkout_token: nil,
          payment_method_id: payment_method.id,
          order_id: order.id,
          use_route: :spree
        }
        expect(response).to redirect_to('/checkout/cart')
      end
    end

    context 'when the order is already completed' do
      let(:order) { create(:completed_order_with_totals) }

      it 'will redirect to the order detail page' do
        post '/affirm_v2/confirm', params: {
          checkout_token: checkout_token,
          payment_method_id: payment_method.id,
          order_id: order.id,
          use_route: :spree
        }
        expect(response).to redirect_to("/orders/#{order.number}")
      end
    end

    context 'with valid data' do
      let(:order) { create(:order_with_totals, state: "payment") }
      let(:affirm_payment_source) { create(:affirm_v2_transaction) }
      let(:checkout_token) { "TKLKJ71GOP9YSASU" }
      let(:transaction_id) { "N330-Z6D4" }
      let(:provider_id) { 1 }
      let!(:affirm_checkout_response) { Affirm::Struct::Transaction.new({ id: transaction_id, checkout_id: checkout_token, amount: 42499, order_id: order.id, provider_id: provider_id }) }

      before do
        allow_any_instance_of(Affirm::Client).to receive(:read_transaction).with(checkout_token).and_return(affirm_checkout_response)
      end

      it "creates a payment" do
        expect {
          post '/affirm_v2/confirm', params: {
            checkout_token: checkout_token,
            payment_method_id: payment_method.id,
            order_id: order.id,
            use_route: :spree
          }
        }.to change{ order.payments.count }.from(0).to(1)
      end

      it "creates a payment with the right amount" do
        post '/affirm_v2/confirm', params: {
          checkout_token: checkout_token,
          payment_method_id: payment_method.id,
          order_id: order.id,
          use_route: :spree
        }
        expect(order.payments.last.amount).to eql 424.99
      end

      it "creates a SolidusAffirmV2::Transaction" do
        expect {
          post '/affirm_v2/confirm', params: {
            checkout_token: checkout_token,
            payment_method_id: payment_method.id,
            order_id: order.id,
            use_route: :spree
          }
        }.to change{ SolidusAffirmV2::Transaction.count }.by(1)
      end

      it "redirect to the confirm page" do
        post '/affirm_v2/confirm', params: {
          checkout_token: checkout_token,
          payment_method_id: payment_method.id,
          order_id: order.id,
          use_route: :spree
        }
        expect(response).to redirect_to('/checkout/confirm')
      end
    end
  end

  describe 'GET cancel' do
    context "with an order_id present" do
      it "will redirect to the current order checkout state" do
        get '/affirm_v2/cancel', params: {
          payment_method_id: payment_method.id,
          order_id: order.id,
          use_route: :spree
        }
        expect(response).to redirect_to('/checkout/cart')
      end
    end
  end
end
