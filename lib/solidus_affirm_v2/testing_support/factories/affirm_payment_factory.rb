# frozen_string_literal: true

FactoryBot.define do
  factory :affirm_v2_payment, class: Spree::Payment do
    source_type { 'SolidusAffirmV2::Transaction' }
    state { 'checkout' }
  end

  factory :captured_affirm_v2_payment, class: Spree::Payment do
    payment_method { create(:affirm_v2_payment_method) }
    source { create(:affirm_v2_transaction) }
  end
end
