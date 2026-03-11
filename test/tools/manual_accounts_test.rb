# frozen_string_literal: true

require "test_helper"

class ManualAccountsToolsTest < Minitest::Test
  def setup
    @client = mock("client")
    @server = LunchMoneyMcp::Server.new(@client)
    LunchMoneyMcp::Tools::ManualAccounts.register(@server)
  end

  def test_registers_all_tools
    %w[get_all_manual_accounts get_manual_account create_manual_account
       update_manual_account delete_manual_account].each do |name|
      assert @server.tool_registered?(name), "Expected #{name} to be registered"
    end
  end

  def test_get_all_manual_accounts
    @client.expects(:get).with("/assets").returns({ "assets" => [] })
    result = @server.call_tool("get_all_manual_accounts", {})
    assert result[:content][0][:text]
  end

  def test_get_manual_account
    account = { "id" => 1, "name" => "Savings" }
    @client.expects(:get).with("/assets/1").returns(account)
    result = @server.call_tool("get_manual_account", { "id" => 1 })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal "Savings", parsed["name"]
  end

  def test_create_manual_account
    body = { "name" => "Cash", "type" => "cash", "balance" => "100.00" }
    @client.expects(:post).with("/assets", body).returns({ "id" => 1 })
    result = @server.call_tool("create_manual_account", body)
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal 1, parsed["id"]
  end

  def test_create_manual_account_with_optional_fields
    body = {
      "name" => "Checking", "type" => "checking", "balance" => "500.00",
      "institution_name" => "Big Bank", "currency" => "usd", "status" => "active"
    }
    @client.expects(:post).with("/assets", body).returns({ "id" => 2 })
    @server.call_tool("create_manual_account", body)
  end

  def test_update_manual_account
    @client.expects(:put).with("/assets/1", { "balance" => "200.00" }).returns({ "id" => 1 })
    @server.call_tool("update_manual_account", { "id" => 1, "balance" => "200.00" })
  end

  def test_delete_manual_account
    @client.expects(:delete).with("/assets/1").returns(nil)
    result = @server.call_tool("delete_manual_account", { "id" => 1 })
    assert_includes result[:content][0][:text], "deleted"
  end
end
