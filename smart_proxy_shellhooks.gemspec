# frozen_string_literal: true
require_relative 'lib/smart_proxy_shellhooks/version'

Gem::Specification.new do |s|
  s.name = 'smart_proxy_shellhooks'
  s.version = Proxy::ShellHooks::VERSION

  s.summary = 'Run shell scripts via Foreman webhooks'
  s.description = 'Provides easy integration with 3rd parties for Foreman'
  s.authors = ['Lukas Zapletal']
  s.email = 'lzap+spam@redhat.com'
  s.extra_rdoc_files = ['README.md', 'LICENSE']
  s.files = Dir['{lib,settings.d,bundler.d,examples}/**/*'] + s.extra_rdoc_files
  s.homepage = 'http://github.com/theforeman/smart_proxy_shellhooks'
  s.license = 'GPL-3.0-or-later'
  s.required_ruby_version = '>= 3.0'
end
