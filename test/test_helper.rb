ENV['RACK_ENV'] = 'test'

require 'test/unit'
require 'mocha/test_unit'
require 'smart_proxy_for_testing'

# Keep test logs in the plugin directory, as in other Smart Proxy plugins.
FileUtils.mkdir_p File.dirname(Proxy::SETTINGS.log_file)

require 'smart_proxy_shellhooks'
require 'smart_proxy_shellhooks/shellhooks_api'
