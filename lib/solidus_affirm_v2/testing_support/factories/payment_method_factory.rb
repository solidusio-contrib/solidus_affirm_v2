# frozen_string_literal: true

FactoryBot.define do
  factory :affirm_v2_payment_method, class: SolidusAffirmV2::PaymentMethod do
    name { "AffirmV2" }
    preferred_public_api_key { "public000" }
    preferred_private_api_key { "private999" }
    preferred_javascript_url { "https://cdn1-sandbox.affirm.com/js/v2/affirm.js" }
  end
end
