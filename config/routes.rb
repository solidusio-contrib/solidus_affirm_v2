# frozen_string_literal: true

Spree::Core::Engine.routes.draw do
  namespace :affirm_v2 do
    post "confirm", controller: SolidusAffirmV2::Config.callback_controller_name
    get "cancel", controller: SolidusAffirmV2::Config.callback_controller_name
  end
end
