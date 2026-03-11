# frozen_string_literal: true

require "test_helper"

class PlaidAccountsToolsTest < Minitest::Test
  def setup
    @client = mock("client")
    @server = LunchMoneyMcp::Server.new(@client)
    LunchMoneyMcp::Tools::PlaidAccounts.register(@server)
  end

  def test_registers_all_tools
    %w[get_all_plaid_accounts get_plaid_account trigger_plaid_fetch].each do |name|
      assert @server.tool_registered?(name), "Expected #{name} to be registered"
    end
  end

  def test_get_all_plaid_accounts
    accounts = [{ "id" => 1, "name" => "Chase Checking" }]
    @client.expects(:get).with("/plaid_accounts").returns(accounts)
    result = @server.call_tool("get_all_plaid_accounts", {})
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal "Chase Checking", parsed[0]["name"]
  end

  def test_get_plaid_account
    account = { "id" => 1, "name" => "Chase Checking" }
    @client.expects(:get).with("/plaid_accounts/1").returns(account)
    result = @server.call_tool("get_plaid_account", { "id" => 1 })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal 1, parsed["id"]
  end

  def test_trigger_plaid_fetch_no_params
    @client.expects(:post).with("/plaid_accounts/fetch", {}).returns(nil)
    result = @server.call_tool("trigger_plaid_fetch", {})
    assert_includes result[:content][0][:text], "triggered"
  end

  def test_trigger_plaid_fetch_with_dates
    body = { "start_date" => "2025-01-01", "end_date" => "2025-01-31" }
    @client.expects(:post).with("/plaid_accounts/fetch", body).returns(nil)
    @server.call_tool("trigger_plaid_fetch", body)
  end

  def test_trigger_plaid_fetch_with_account_id
    @client.expects(:post).with("/plaid_accounts/fetch", { "id" => 5 }).returns(nil)
    @server.call_tool("trigger_plaid_fetch", { "id" => 5 })
  end
end
