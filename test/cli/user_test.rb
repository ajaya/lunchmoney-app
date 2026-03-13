# frozen_string_literal: true

require "test_helper"

class CliUserTest < Minitest::Test
  def setup
    LunchMoneyApp::Cache.new(":memory:")
    LunchMoneyApp::Cli::Main.stubs(:setup_from_config!)

    @sdk_api = mock("me_api")
    LunchMoney::MeApi.stubs(:new).returns(@sdk_api)
  end

  def test_me_json
    user = stub(id: 1, to_hash: { "id" => 1, "name" => "Alice", "email" => "alice@example.com", "budget_name" => "Personal" })
    @sdk_api.expects(:get_me).returns(user)
    out = capture_stdout { LunchMoneyApp::Cli::User.start(%w[me --json]) }
    parsed = JSON.parse(out)
    assert_equal "Alice", parsed["name"]
    assert_equal "alice@example.com", parsed["email"]
  end

  def test_me_human
    user = stub(id: 1, to_hash: { "id" => 1, "name" => "Alice", "email" => "alice@example.com", "budget_name" => "Personal" })
    @sdk_api.expects(:get_me).returns(user)
    out = capture_stdout { LunchMoneyApp::Cli::User.start(%w[me]) }
    assert_includes out, "Alice"
    assert_includes out, "alice@example.com"
    assert_includes out, "Personal"
  end

  def test_me_via_main
    user = stub(id: 1, to_hash: { "id" => 1, "name" => "Bob", "email" => "bob@test.com", "budget_name" => "" })
    @sdk_api.expects(:get_me).returns(user)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[user me]) }
    assert_includes out, "Bob"
    refute_includes out, "Budget:"
  end
end
