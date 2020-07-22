# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SolidusAffirmV2::Gateway do
  let(:gateway_options) do
    {
      public_api_key: "PUBLIC_API_KEY",
      private_api_key: "PRIVATE_API_KEY",
      test_mode: true
    }
  end

  let(:checkout_token) { "TKLKJ71GOP9YSASU" }
  let(:transaction_id) { "N330-Z6D4" }
  let(:affirm_v2_transaction) { create(:affirm_v2_transaction, checkout_token: checkout_token) }

  let(:affirm_transaction_event_response) do
    Affirm::Struct::Transaction::Event.new({})
  end

  subject do
    SolidusAffirmV2::Gateway.new(gateway_options)
  end

  describe "initialize" do
    it "will setup Affirm::Client config" do
      subject
      expect(Affirm.config.public_api_key).to eql "PUBLIC_API_KEY"
      expect(Affirm.config.private_api_key).to eql "PRIVATE_API_KEY"
      expect(Affirm.config.environment).to eql :sandbox
    end
  end

  describe "#authorize" do
    let(:affirm_transaction_response) { Affirm::Struct::Transaction.new({ id: transaction_id, provider_id: 2 }) }
    let(:am_response) { subject.authorize(nil, affirm_v2_transaction) }

    before do
      allow_any_instance_of(::Affirm::Client).to receive(:authorize).and_return(affirm_transaction_response)
    end

    context "with valid data" do
      it "will returna successfull ActiveMerchant::Response" do
        expect(am_response.success?).to be_truthy
      end

      it "will set the Affirm transaction_id" do
        expect(am_response.authorization).to eql transaction_id
      end

      it "will return a 'Transaction Approved' message" do
        expect(am_response.message).to eql "Transaction Approved"
      end
    end

    context "with invalid data" do
      before do
        allow_any_instance_of(::Affirm::Client).to receive(:authorize).and_raise(Affirm::RequestError, "The transaction has already been authorized.")
      end

      it "will return an unsuccesfull ActiveMerchant::Response" do
        expect(am_response.success?).to be_falsy
      end

      it "will return the error message from Affirm in the response" do
        expect(am_response.message).to eql "The transaction has already been authorized."
      end
    end
  end

  describe "#capture" do
    let(:am_response) { subject.capture(nil, transaction_id) }

    before do
      allow_any_instance_of(::Affirm::Client).to receive(:capture).with(transaction_id).and_return(affirm_transaction_event_response)
    end

    it "will capture the affirm payment with the transaction_id" do
      expect(am_response.success?).to be_truthy
    end

    context "with invalid data" do
      before do
        allow_any_instance_of(::Affirm::Client).to receive(:capture).with(transaction_id).and_raise(Affirm::RequestError.new("The transaction has already been captured."))
      end

      it "will return an unsuccesfull response" do
        expect(am_response.success?).to be_falsy
      end

      it "will return the error message from Affirm in the response" do
        expect(am_response.message).to eql "The transaction has already been captured."
      end
    end
  end

  describe "#void" do
    let(:am_response) { subject.void(transaction_id, nil) }

    context "on an authorized payment" do
      before do
        allow_any_instance_of(::Affirm::Client).to receive(:void).with(transaction_id).and_return(affirm_transaction_event_response)
      end

      it "will void the payment in Affirm" do
        expect(am_response.success?).to be_truthy
        expect(am_response.message).to eql "Transaction Voided"
      end
    end

    context "on a captured payment" do
      before do
        allow_any_instance_of(::Affirm::Client).to receive(:void).with(transaction_id).and_raise(Affirm::RequestError.new("The transaction has already been captured."))
      end

      it "will return an unsuccesfull response" do
        expect(am_response.success?).to be_falsy
      end

      it "will return the error message from Affirm in the response" do
        expect(am_response.message).to eql ("The transaction has already been captured.")
      end
    end
  end

  describe "#credit" do
    let(:am_response) { subject.credit(money, transaction_id, nil) }
    let(:money) { 1000 }

    context "on an captured payment" do
      before do
        allow_any_instance_of(::Affirm::Client).to receive(:refund).with(transaction_id, money).and_return(affirm_transaction_event_response)
      end

      it "will refund a part or the whole payment amount" do
        expect(am_response.success?).to be_truthy
        expect(am_response.message).to eql "Transaction Credited with #{money}"
      end
    end

    context "on an already voided payment" do
      before do
        allow_any_instance_of(::Affirm::Client).to receive(:refund).with(transaction_id, money).and_raise(Affirm::RequestError.new("The transaction has been voided and cannot be refunded."))
      end

      it "will return an unsuccesfull response" do
        expect(am_response.success?).to be_falsy
      end

      it "will return the error message from Affirm in the response" do
        expect(am_response.message).to eql "The transaction has been voided and cannot be refunded."
      end
    end
  end
end
