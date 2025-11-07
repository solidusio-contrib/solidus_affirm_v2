# frozen_string_literal: true

require 'spree/core'
require 'solidus_affirm_v2'

module SolidusAffirmV2
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions

    isolate_namespace ::Spree

    engine_name 'solidus_affirm_v2'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "register_solidus_affirm_v2_payment_method", after: "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << "SolidusAffirmV2::PaymentMethod"
    end

    initializer "register_solidus_affirm_v2_configuration", before: :load_config_initializers do |_app|
      Rails.application.config.to_prepare do
        SolidusAffirmV2::Config = SolidusAffirmV2::Configuration.new
      end
    end

    initializer 'register_solidus_affirm_v2_helper_action_controller' do |_app|
      ActiveSupport.on_load :action_controller do |klass|
        next if klass.name == "ActionController::API"

        helper SolidusAffirmV2::AffirmHelper
      end
    end
  end
end
