# frozen_string_literal: true

require "test_helper"

class PlaidAccountsToolsTest < Minitest::Test
  def setup
    @server = build_server
    LunchMoneyApp::Tools::PlaidAccounts.register(@server)

    @sdk_api = mock("plaid_accounts_api")
    LunchMoney::PlaidAccountsApi.stubs(:new).returns(@sdk_api)
  end

  def test_registers_all_tools
    %w[get_all_plaid_accounts get_plaid_account trigger_plaid_fetch].each do |name|
      assert @server.tools.key?(name), "Expected #{name} to be registered"
    end
  end

  def test_get_all_plaid_accounts
    response = stub(plaid_accounts: [], to_hash: { "plaid_accounts" => [] })
    @sdk_api.expects(:get_all_plaid_accounts).returns(response)
    result = call_tool(@server, "get_all_plaid_accounts")
    assert result[:content][0][:text]
  end

  def test_get_plaid_account
    account = stub(id: 1, to_hash: { "id" => 1, "name" => "Chase Checking" })
    @sdk_api.expects(:get_plaid_account_by_id).with(1).returns(account)
    result = call_tool(@server, "get_plaid_account", { id: 1 })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal 1, parsed["id"]
  end

  def test_trigger_plaid_fetch_no_params
    @sdk_api.expects(:trigger_plaid_account_fetch).returns(nil)
    result = call_tool(@server, "trigger_plaid_fetch")
    assert_includes result[:content][0][:text], "triggered"
  end

  def test_trigger_plaid_fetch_with_dates
    @sdk_api.expects(:trigger_plaid_account_fetch)
            .with(start_date: "2025-01-01", end_date: "2025-01-31").returns(nil)
    call_tool(@server, "trigger_plaid_fetch", { start_date: "2025-01-01", end_date: "2025-01-31" })
  end

  def test_trigger_plaid_fetch_with_account_id
    @sdk_api.expects(:trigger_plaid_account_fetch).with(id: 5).returns(nil)
    call_tool(@server, "trigger_plaid_fetch", { id: 5 })
  end
end
