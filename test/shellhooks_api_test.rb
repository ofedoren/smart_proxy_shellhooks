require_relative 'test_helper'
require 'stringio'
require 'tmpdir'
require 'fileutils'
require 'rack/mock'
require 'rackup/handler/webrick' if Rack.release.start_with?('3.')

class ShellhooksApiTest < Test::Unit::TestCase
  # Implements the Rack 3 input interface without rewind.
  class ForwardOnlyInput
    def initialize(body)
      @io = StringIO.new(body)
    end

    def read(*args)
      @io.read(*args)
    end

    def gets(*args)
      @io.gets(*args)
    end

    def each(&block)
      @io.each(&block)
    end
  end

  def setup
    @directory = Dir.mktmpdir('shellhooks')
    @script = File.join(@directory, 'print_body')
    File.write(@script, "#!/bin/sh\ncat\n")
    File.chmod(0700, @script)
    Proxy::ShellHooks::Plugin.load_test_settings(:directory => @directory)
    Proxy::ShellHooks::Api.any_instance.stubs(:logger).returns(stub(:debug => nil))
  end

  def teardown
    FileUtils.remove_entry(@directory) if @directory
  end

  def test_plain_text_payload
    assert_payload("hello\nworld\n", 'text/plain')
  end

  def test_json_payload
    assert_payload('{"message":"hello"}', 'application/json')
  end

  def test_form_payload_after_parameter_parsing
    assert_payload('message=hello+world&name=another_hook', 'application/x-www-form-urlencoded')
  end

  def test_empty_payload
    assert_payload('', 'text/plain')
  end

  def test_rewindable_input
    assert_payload('message=hello', 'application/x-www-form-urlencoded', StringIO.new('message=hello'))
  end

  if Rack.release.start_with?('3.')
    def test_webrick_input
      payload = 'message=hello+world'
      request = stub('WEBrick request')
      request.stubs(:body).yields(payload)
      input = Rackup::Handler::WEBrick::Input.new(request)
      assert_payload(payload, 'application/x-www-form-urlencoded', input)
    end
  end

  private

  def assert_payload(payload, content_type, input = nil)
    # Rack 2 requires rewindable input; Rack 3 permits forward-only streams.
    input ||= Rack.release.start_with?('2.') ? StringIO.new(payload) : ForwardOnlyInput.new(payload)
    task = mock('command task')
    task.expects(:start).returns('')
    Proxy::Util::CommandTask.expects(:new).with([@script, 'an argument'], payload).returns(task)

    env = Rack::MockRequest.env_for('/print_body',
      :method => 'POST',
      'CONTENT_TYPE' => content_type,
      'CONTENT_LENGTH' => payload.bytesize.to_s,
      'HTTP_X_SHELLHOOK_ARG_1' => 'an argument')
    env['rack.input'] = input
    status, _, body = Proxy::ShellHooks::Api.call(env)
    assert_equal 200, status
  ensure
    body.close if body.respond_to?(:close)
    env['rack.input'].close if env && env['rack.input'].respond_to?(:close)
  end
end
