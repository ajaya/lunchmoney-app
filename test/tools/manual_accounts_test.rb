# frozen_string_literal: true

require "test_helper"

class ManualAccountsToolsTest < Minitest::Test
  def setup
    @server = build_server
    LunchMoneyApp::Tools::ManualAccounts.register(@server)

    @sdk_api = mock("manual_accounts_api")
    LunchMoney::ManualAccountsApi.stubs(:new).returns(@sdk_api)
  end

  def test_registers_all_tools
    %w[get_all_manual_accounts get_manual_account create_manual_account
       update_manual_account delete_manual_account].each do |name|
      assert @server.tools.key?(name), "Expected #{name} to be registered"
    end
  end

  def test_get_all_manual_accounts
    response = stub(manual_accounts: [], to_hash: { "assets" => [] })
    @sdk_api.expects(:get_all_manual_accounts).returns(response)
    result = call_tool(@server, "get_all_manual_accounts")
    assert result[:content][0][:text]
  end

  def test_get_manual_account
    account = stub(id: 1, to_hash: { "id" => 1, "name" => "Savings" })
    @sdk_api.expects(:get_manual_account_by_id).with(1).returns(account)
    result = call_tool(@server, "get_manual_account", { id: 1 })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal "Savings", parsed["name"]
  end

  def test_create_manual_account
    @sdk_api.expects(:create_manual_account).returns({ "id" => 1 })
    result = call_tool(@server, "create_manual_account", { name: "Cash", type: "cash", balance: "100.00" })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal 1, parsed["id"]
  end

  def test_update_manual_account
    @sdk_api.expects(:update_manual_account).with(1, { "balance" => "200.00" }).returns({ "id" => 1 })
    call_tool(@server, "update_manual_account", { id: 1, balance: "200.00" })
  end

  def test_delete_manual_account
    @sdk_api.expects(:delete_manual_account).with(1, delete_items: nil, delete_balance_history: nil).returns(nil)
    result = call_tool(@server, "delete_manual_account", { id: 1 })
    assert_includes result[:content][0][:text], "deleted"
  end
end
