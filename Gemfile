# frozen_string_literal: true

source 'https://rubygems.org'
gemspec

group :test do
  gem 'mocha'
  gem 'rake'
  gem 'smart_proxy', github: 'theforeman/smart-proxy', branch: ENV.fetch('SMART_PROXY_BRANCH', 'develop')
  gem 'test-unit'
end
