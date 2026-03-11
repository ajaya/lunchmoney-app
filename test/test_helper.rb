# frozen_string_literal: true

require "minitest/autorun"
require "minitest/reporters"
require "mocha/minitest"
require "webmock/minitest"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require "zeitwerk"
require "json"
require "net/http"
require "uri"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

loader = Zeitwerk::Loader.new
loader.inflector.inflect("lunchmoney_mcp" => "LunchMoneyMcp")
loader.push_dir(File.expand_path("../lib", __dir__))
loader.setup
loader.eager_load

module TestHelpers
  # Returns a server with a stub client, and the stub client itself.
  def build_server
    client = mock("client")
    server = LunchMoneyMcp::Server.new(client)
    [server, client]
  end

  # Registers the given tool class and calls a named tool with args.
  def call(tool_class, tool_name, args = {}, client: nil)
    c = client || mock("client")
    s = LunchMoneyMcp::Server.new(c)
    tool_class.register(s)
    s.call_tool(tool_name, args)
  end
end

class Minitest::Test
  include TestHelpers
end
