# frozen_string_literal: true

require "affirm"

module SolidusAffirmV2
  class Gateway
    def initialize(options)
      ::Affirm.configure do |config|
        config.public_api_key = options[:public_api_key]
        config.private_api_key = options[:private_api_key]
        config.environment = options[:test_mode] ? :sandbox : :production
      end
    end

    def authorize(_money, affirm_source, _options = {})
      response = ::Affirm::Client.new.authorize(affirm_source.checkout_token)

      SolidusAffirmV2::Transaction
        .find_by(checkout_token: affirm_source.checkout_token)
        .update(transaction_id: response.id)

      ActiveMerchant::Billing::Response.new(true, "Transaction Approved", {}, authorization: response.id)
    rescue Affirm::Error => e
      ActiveMerchant::Billing::Response.new(false, e.message)
    end

    def capture(_money, transaction_id, _options = {})
      _response = ::Affirm::Client.new.capture(transaction_id)
      ActiveMerchant::Billing::Response.new(true, "Transaction Captured", authorization: transaction_id)
    rescue Affirm::Error => e
      ActiveMerchant::Billing::Response.new(false, e.message)
    end

    def void(transaction_id, _money, _options = {})
      _response = ::Affirm::Client.new.void(transaction_id)
      ActiveMerchant::Billing::Response.new(true, "Transaction Voided")
    rescue Affirm::Error => e
      ActiveMerchant::Billing::Response.new(false, e.message)
    end

    def credit(money, transaction_id, _options = {})
      _response = ::Affirm::Client.new.refund(transaction_id, money)
      ActiveMerchant::Billing::Response.new(true, "Transaction Credited with #{money}")
    rescue Affirm::Error => e
      ActiveMerchant::Billing::Response.new(false, e.message)
    end

    def purchase(money, affirm_source, options = {})
      result = authorize(money, affirm_source, options)
      return result unless result.success?

      capture(money, result.authorization, options)
    end

    def try_void(payment)
      transaction_id = payment.source.transaction_id
      begin
        transaction = get_transaction(transaction_id)
      rescue Affirm::Error => e
        return ActiveMerchant::Billing::Response.new(false, e.message)
      end

      if transaction.status == "authorized"
        void(transaction_id, nil, {})
      else
        false
      end
    end

    def get_transaction(transaction_id)
      ::Affirm::Client.new.read_transaction(transaction_id)
    end

    def get_checkout(checkout_token)
      ::Affirm::Client.new.get_checkout(checkout_token)
    end
  end
end
