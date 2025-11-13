# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolidusAffirmV2::Gateway do
  let(:gateway) {
    described_class.new(gateway_options)
  }
  let(:gateway_options) {
    {
      public_api_key: "PUBLIC_API_KEY",
      private_api_key: "PRIVATE_API_KEY",
      test_mode: true
    }
  }
  let(:checkout_token) { "TKLKJ71GOP9YSASU" }
  let(:transaction_id) { "N330-Z6D4" }

  let(:affirm_transaction_event_response) do
    Affirm::Struct::Transaction::Event.new(id: transaction_id)
  end

  describe "initialize" do
    before { gateway }

    it "sets the public_api_key in Affirm config" do
      expect(Affirm.config.public_api_key).to eql "PUBLIC_API_KEY"
    end

    it "sets the private_api_key in Affirm config" do
      expect(Affirm.config.private_api_key).to eql "PRIVATE_API_KEY"
    end

    it "sets the config environment to sandbox" do
      expect(Affirm.config.environment).to be :sandbox
    end
  end

  describe "#authorize" do
    subject { gateway.authorize(nil, affirm_v2_transaction) }

    let(:affirm_transaction_response) { Affirm::Struct::Transaction.new({id: transaction_id, provider_id: 2}) }
    let(:affirm_v2_transaction) { create(:affirm_v2_transaction, transaction_id: nil, checkout_token:) }

    before do
      allow_any_instance_of(::Affirm::Client)
        .to receive(:authorize)
        .with(checkout_token)
        .and_return(affirm_transaction_response)
    end

    context "with valid data" do
      it "returns successfull ActiveMerchant::Response" do
        expect(subject).to be_success
      end

      it "sets the Affirm transaction_id" do
        expect(subject.authorization).to eql transaction_id
      end

      it "returns a 'Transaction Approved' message" do
        expect(subject.message).to eql "Transaction Approved"
      end

      it "updates the transaction id on the transaction" do
        expect { subject }
          .to change { affirm_v2_transaction.reload.transaction_id }
          .from(nil).to(transaction_id)
      end
    end

    context "with invalid data" do
      before do
        allow_any_instance_of(::Affirm::Client)
          .to receive(:authorize)
          .with(checkout_token)
          .and_raise(Affirm::RequestError, "The transaction has already been authorized.")
      end

      it "returns an unsuccesfull ActiveMerchant::Response" do
        expect(subject).not_to be_success
      end

      it "returns the error message from Affirm in the response" do
        expect(subject.message).to eql "The transaction has already been authorized."
      end
    end
  end

  describe "#capture" do
    subject { gateway.capture(nil, transaction_id) }

    before do
      allow_any_instance_of(::Affirm::Client)
        .to receive(:capture)
        .with(transaction_id)
        .and_return(affirm_transaction_event_response)
    end

    it "captures the affirm payment with the transaction_id" do
      expect(subject).to be_success
    end

    context "with invalid data" do
      before do
        allow_any_instance_of(::Affirm::Client)
          .to receive(:capture)
          .with(transaction_id)
          .and_raise(Affirm::RequestError.new("The transaction has already been captured."))
      end

      it "returns an unsuccesfull response" do
        expect(subject).not_to be_success
      end

      it "returns the error message from Affirm in the response" do
        expect(subject.message).to eql "The transaction has already been captured."
      end
    end
  end

  describe "#void" do
    subject { gateway.void(transaction_id, nil) }

    context "with an authorized payment" do
      before do
        allow_any_instance_of(::Affirm::Client)
          .to receive(:void)
          .with(transaction_id)
          .and_return(affirm_transaction_event_response)
      end

      it "voids the payment in Affirm" do
        expect(subject.message).to eql "Transaction Voided"
      end
    end

    context "with a captured payment" do
      before do
        allow_any_instance_of(::Affirm::Client)
          .to receive(:void)
          .with(transaction_id)
          .and_raise(Affirm::RequestError.new("The transaction has already been captured."))
      end

      it "returns an unsuccesfull response" do
        expect(subject).not_to be_success
      end

      it "returns the error message from Affirm in the response" do
        expect(subject.message).to eql "The transaction has already been captured."
      end
    end
  end

  describe "#credit" do
    subject { gateway.credit(money, transaction_id, nil) }

    let(:money) { 1000 }

    context "with a captured payment" do
      before do
        allow_any_instance_of(::Affirm::Client)
          .to receive(:refund)
          .with(transaction_id, money)
          .and_return(affirm_transaction_event_response)
      end

      it "refunds a part or the whole payment amount" do
        expect(subject.message).to eql "Transaction Credited with #{money}"
      end

      it "includes the authorization in the return" do
        expect(subject.authorization)
          .to eq "N330-Z6D4"
      end
    end

    context "with an already voided payment" do
      before do
        allow_any_instance_of(::Affirm::Client)
          .to receive(:refund)
          .with(transaction_id, money)
          .and_raise(Affirm::RequestError.new("The transaction has been voided and cannot be refunded."))
      end

      it "returns an unsuccesfull response" do
        expect(subject).not_to be_success
      end

      it "returns the error message from Affirm in the response" do
        expect(subject.message).to eql "The transaction has been voided and cannot be refunded."
      end
    end
  end
end
