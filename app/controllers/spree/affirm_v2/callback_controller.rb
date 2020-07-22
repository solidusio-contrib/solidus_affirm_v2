# frozen_string_literal: true

module Spree
  module AffirmV2
    class CallbackController < Spree::StoreController
      protect_from_forgery except: [:confirm]

      def confirm
        checkout_token = affirm_params[:checkout_token]
        order = Spree::Order.find(affirm_params[:order_id])
        payment_method = SolidusAffirmV2::PaymentMethod.find(affirm_params[:payment_method_id])

        if !checkout_token
          return redirect_to checkout_state_path(order.state), notice: "Invalid order confirmation data passed in"
        end

        if order.complete?
          return redirect_to spree.order_path(order), notice: "Order is already in complete state"
        end

        affirm_transaction_object = payment_method.gateway.get_transaction(checkout_token)
        
        affirm_source_transaction = SolidusAffirmV2::Transaction.new(
          transaction_id: affirm_transaction_object.id,
          checkout_token: affirm_transaction_object.checkout_id,
          provider: affirm_transaction_object.provider
        )

        affirm_source_transaction.transaction do
          if affirm_source_transaction.save!
            payment = order.payments.create!({
              payment_method_id: affirm_params[:payment_method_id],
              source: affirm_source_transaction,
              amount: affirm_transaction_object.amount / 100.0
            })
            
            order.next! unless order.state == 'confirm'
            redirect_to checkout_state_path(order.state)
          end
        end
      end

      def cancel
        order = Spree::Order.find(affirm_params[:order_id])
        hook = SolidusAffirmV2::Config.callback_hook.new
        redirect_to hook.after_cancel_url(order)
      end

      private

      def affirm_params
        params.permit(:checkout_token, :payment_method_id, :order_id)
      end
    end
  end
end
