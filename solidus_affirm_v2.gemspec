# frozen_string_literal: true

require_relative 'lib/solidus_affirm_v2/version'

Gem::Specification.new do |spec|
  spec.name = 'solidus_affirm_v2'
  spec.version = SolidusAffirmV2::VERSION
  spec.authors = ['Peter Berkenbosch']
  spec.email = 'info@peterberkenbosch.nl'

  spec.summary = 'Solidus extension for using Affirm financing payments in your store'
  spec.description = 'Solidus extenstion that integrates your store with Affirm financing payments using the new Transaction API '
  spec.homepage = 'https://github.com/solidusio-contrib/solidus_affirm_v2'
  spec.license = 'BSD-3-Clause'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/solidusio-contrib/solidus_affirm_v2'
  spec.metadata['changelog_uri'] = 'https://github.com/solidusio-contrib/solidus_affirm_v2/releases'

  spec.required_ruby_version = Gem::Requirement.new('~> 2.4')

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  files = Dir.chdir(__dir__) { `git ls-files -z`.split("\x0") }

  spec.files = files.grep_v(%r{^(test|spec|features)/})
  spec.test_files = files.grep(%r{^(test|spec|features)/})
  spec.bindir = "exe"
  spec.executables = files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'solidus_core', ['>= 2.0.0', '< 3']
  spec.add_dependency 'solidus_support', '~> 0.5'
  spec.add_dependency 'active_model_serializers', '~> 0.10'
  spec.add_dependency 'affirm-ruby-api', '~> 1.0'
  
  spec.add_development_dependency 'solidus_dev_support'
  spec.add_development_dependency 'webmock'
end
