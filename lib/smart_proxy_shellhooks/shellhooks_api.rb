require 'sinatra'
require 'rack/rewindable_input'
require 'smart_proxy_shellhooks/shellhooks'

module Proxy::ShellHooks
  VALID_SHELL = Regexp.compile(/[a-z0-9_-]+/)

  class Api < ::Sinatra::Base
    include ::Proxy::Log
    helpers ::Proxy::Helpers

    # Rack 3 inputs need buffering so parameter parsing does not consume the payload.
    use Rack::RewindableInput::Middleware if defined?(Rack::RewindableInput::Middleware)

    authorize_with_ssl_client
    authorize_with_trusted_hosts

    get '/' do
      executable = []
      other = []
      Dir.each_child(Plugin.settings.directory) do |filename|
        file = File.join(Plugin.settings.directory, filename)
        if valid_shell?(file)
          executable.append(filename)
        else
          other.append(filename)
        end
      end
      {valid: executable, invalid: other}.to_json
    end

    post '/:name' do
      name = params['name']
      log_halt(500, "Not a valid shellhook name") if name !~ VALID_SHELL
      file = File.join(Plugin.settings.directory, name)
      log_halt(500, "Not a valid shellhook file") unless valid_shell?(file)
      cmd = [file]
      (1..99).each_with_index do |i|
        arg_name = "HTTP_X_SHELLHOOK_ARG_#{i}"
        if request.env[arg_name]
          cmd << request.env[arg_name]
        else
          break
        end
      end
      # Sinatra may have already read the body while parsing form parameters.
      request.body.rewind
      Proxy::Util::CommandTask.new(cmd, request.body.read).start
    end

    private

    def valid_shell?(file)
      File.executable_real?(file) && File.file?(file) && file =~ VALID_SHELL
    end
  end
end
