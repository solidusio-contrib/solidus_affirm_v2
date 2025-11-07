# frozen_string_literal: true

require "spec_helper"

RSpec.describe SolidusAffirmV2::PaymentMethod do
  subject(:payment_method) { create(:affirm_v2_payment_method) }

  describe "gateway" do
    it "returns a SolidusAffirmV2::Gateway instance" do
      expect(payment_method.gateway).to be_a SolidusAffirmV2::Gateway
    end
  end

  describe "payment_source_class" do
    it "returns a SolidusAffirmV2::Transaction class" do
      expect(payment_method.payment_source_class).to eql SolidusAffirmV2::Transaction
    end
  end

  describe "partial_name" do
    it "returns affirm_v2" do
      expect(payment_method.partial_name).to eql "affirm_v2"
    end
  end

  describe "supports?" do
    it "returns true with SolidusAffirmV2::Transaction source" do
      expect(payment_method).to be_supports(SolidusAffirmV2::Transaction.new)
    end
  end
end
