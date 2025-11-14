# SolidusAffirmV2

Port and minor upgrade from [solidus_affirm](https://github.com/solidusio/solidus_affirm) using the [new Affirm Transaction API](https://docs.affirm.com/affirm-developers/changelog/transactions-api).


This extension uses the [Direct Connect API](https://docs.affirm.com/affirm-developers/docs/direct-connect-api) to integrate with Affirm.

**The work done before October 1st 2020 is sponsored by the [Solidus Open Collective fund](https://opencollective.com/solidus)**

## Installation

Add solidus_affirm_v2 to your Gemfile:

```ruby
gem 'solidus_affirm_v2'
```

or use it directly from Github like this:

```ruby
gem 'solidus_affirm_v2', github: 'solidusio-contrib/solidus_affirm_v2'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g solidus_affirm_v2:install
```

## Configuration

To generate the correct URL's in the JSON payload we need to specify the
`default_url_options` for the Solidus engine. You can do that like this:

```
Spree::Core::Engine.routes.default_url_options = {
  host: 'example.com'
}
```

You will need to get your public and private API keys from the Affirm Dashboard, see the [Affirm Documentation](https://docs.affirm.com/affirm-developers/docs/direct-connect-api).

When you configure the payment gateway you need to provide those keys to
the payment gateway and also the link to the Affirm JS Runtime script.

Make sure that during development and testing you use the sandbox version:
* Sandbox = https://cdn1-sandbox.affirm.com/js/v2/affirm.js
* Live = https://cdn1.affirm.com/js/v2/affirm.js

### Configure via database configuration

If you want to store your Affirm credentials in the database just
fill the new fields in the form, selecting `custom` (default) in the
Preference Source field.

### Configure via static configuration

If you want to store your credentials into your codebase or use ENV
variables you can create the following static configuration:

```ruby
# config/initializers/spree.rb

Spree.config do |config|
  # ...
  config.static_model_preferences.add(
    "SolidusAffirmV2::PaymentMethod",
    'affirm_env_credentials',
    public_api_key: ENV['AFFIRM_PUBLIC_KEY'],
    private_api_key: ENV['AFFIRM_PRIVATE_KEY'],
    javascript_url: ENV['AFFIRM_JS_RUNTIME_URL'],
    test_mode: !Rails.env.production?
  )
end
```

Once your server has been restarted, you can select `affirm_env_credentials` in
the Preference Source field. After saving, your application will start using the
static configuration to process Affirm payments.

## Hooks and extension points

We provide a configuration class the allows you customize the complete setup.

To do so, you can use the `SolidusAffirmV2::Config` class in an initializer,
like `config/initializers/spree.rb` for example.

### Callback controller

When performing a checkout on Affirm, there are 2 callbacks that Affirm
could send to our system.

1) a `POST` to the `confirm` action.
2) a `GET` to the `cancel` action.

To change the controller that is handling those actions you can specify
the route name like this:

```ruby
SolidusAffirmV2::Config.callback_controller_name = 'my_custom_affirm'
```

Since the routes file here is within the `Spree` and `AffirmV2` namespace you will have to
provide the controller in that namespace. So with the above sample, `my_controller`,
you should define a controller like this:

```ruby
class Spree::AffirmV2::MyCustomAffirmController < Spree::StoreController
  def confirm
    #implement your own confirm action here.
  end

  def cancel
    #implement your own cancel action here.
  end
end
```

Note that you could inherit from the provided controller as well if you
just want to override one part. The default controller we have setup here
is `Spree::AffirmV2::CallbackController`.

If you just need to change the way you like to handle the confirm and cancel
actions, read below. We provide a hook for that as well.

### Callback flow for confirming and canceling

For confirming or canceling an Affirm payment we provide sane defaults for
that in the `SolidusAffirmV2::CallbackHook::Base` class.

That class provides 3 methods that we use in the controller for:
* setup the payment on the order correctly and use the checkout state_machine
* the redirect url after the confirm action is done
* the redirect url after the cancel action

To change that behaviour you can provide your own callback hook class like this:

```ruby
class MyCallbackHook < SolidusAffirmV2::CallbackHook::Base
  def authorize!(payment)
    #do your magic here.
  end

  def after_authorize_url(order)
    'sample/endpoint/success'
  end

  def after_cancel_url(order)
    'sample/endpoint/cancel'
  end
end
```

Then configure this class name in an initializer like this:

```ruby
SolidusAffirmV2::Config.callback_hook = MyCallbackHook
```

### Checkout payload serializer

To generate the JSON payload for the order that Affirm needs to setup the
payment we provide a default serializer in `SolidusAffirmV2::CheckoutPayloadSerializer`.

You can change that by providing your custom serializer. If you just need to
override a few attributes you should inherit from `SolidusAffirmV2::CheckoutPayloadSerializer` and just provide the implementations of the attributes you would like to change. The untouched attributes will be inherited by default.

For example, to just override the shipping attribute you can do something like this:

```ruby
class MyCustomPayloadSerializer < SolidusAffirmV2::CheckoutPayloadSerializer
  def shipping
    MyCustomAddressSerializerImpl(object.ship_address)
  end
end
```

Then configure this new class to be the serializer:

```ruby
SolidusAffirmV2::Config.checkout_payload_serializer = MyCustomPayloadSerializer
```

## Testing

First bundle your dependencies, then run `bin/rake`. `bin/rake` will default to building the dummy app if it does not exist, then it will run specs. The dummy app can be regenerated by using `bin/rake extension:test_app`.

```shell
bundle
bin/rake
```

To run [Standard](https://github.com/standardrb/standard)

```shell
bundle exec standardrb --fix
```

When testing your application's integration with this extension you may use its factories.
Simply add this require statement to your spec_helper:

```ruby
require 'solidus_affirm_v2/factories'
```

## Sandbox app

To run this extension in a sandboxed Solidus application you can run `bin/sandbox`
The path for the sandbox app is `./sandbox` and `bin/rails` will forward any Rails command
to `sandbox/bin/rails`.

Example:

```shell
$ bin/rails server
=> Booting Puma
=> Rails 6.0.2.1 application starting in development
* Listening on tcp://127.0.0.1:3000
Use Ctrl-C to stop
```

## Releasing

Your new extension version can be released using `gem-release` like this:

```shell
bundle exec gem bump -v VERSION --tag --push --remote upstream && gem release
```

Copyright (c) 2020 Peter Berkenbosch, released under the New BSD License
