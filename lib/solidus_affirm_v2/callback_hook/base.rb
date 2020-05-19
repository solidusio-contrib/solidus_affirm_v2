# frozen_string_literal: true

module SolidusAffirmV2
  module CallbackHook
    class Base
      def authorize!(payment)
        payment.process!
        authorized_affirm = Affirm::Client.new.read_transaction(payment.response_code)

        # TODO: have a better solution for this.
        provider = SolidusAffirmV2::Transaction::PROVIDERS[authorized_affirm.provider_id-1]

        payment.source.update_attributes(
          {
            transaction_id: authorized_affirm.id,
            provider: provider
          }
        )

        remove_tax!(payment.order) if authorized_affirm.provider_id == :katapult

        payment.amount = authorized_affirm.amount / 100.0
        payment.save!
        payment.order.next! if payment.order.payment?
      end

      def after_authorize_url(order)
        order_state_checkout_path(order)
      end

      def after_cancel_url(order)
        order_state_checkout_path(order)
      end

      protected

      def remove_tax!(order)
      end

      private

      def order_state_checkout_path(order)
        Spree::Core::Engine.routes.url_helpers.checkout_state_path(order.state)
      end
    end
  end
end
