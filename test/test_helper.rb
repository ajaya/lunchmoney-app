# frozen_string_literal: true

require "minitest/autorun"
require "minitest/reporters"
require "mocha/minitest"
require "webmock/minitest"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

require "zeitwerk"
require "json"
require "sequel"
require "lunchmoney-sdk-ruby"

# Sequel models need a DB with tables at class-definition time; Cache.new replaces it later.
db = Sequel.sqlite
%i[transactions categories tags plaid_accounts manual_accounts recurring_items budgets users].each do |t|
  db.create_table?(t) do
    Integer :id, primary_key: true
    column :data, :text, null: false
    DateTime :synced_at, null: false
  end
end
Sequel::Model.db = db

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

loader = Zeitwerk::Loader.new
loader.inflector.inflect("lunchmoney_app" => "LunchMoneyApp")
loader.push_dir(File.expand_path("../lib", __dir__))
loader.setup
loader.eager_load

module TestHelpers
  # Creates an in-memory cache (reconnects Sequel models) and returns an MCP::Server.
  def build_server
    LunchMoneyApp::Cache.new(":memory:")
    MCP::Server.new(name: "test", version: "0.0.1")
  end

  # Call an MCP tool via the server's handle method (JSON-RPC).
  # Returns the result hash (e.g. {content: [...], isError: false}).
  def call_tool(server, name, arguments = {})
    request = {
      jsonrpc: "2.0",
      id: 1,
      method: "tools/call",
      params: { name: name, arguments: arguments }
    }
    response = server.handle(request)
    response[:result]
  end

  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end
end

class Minitest::Test
  include TestHelpers
end
