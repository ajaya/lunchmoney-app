# frozen_string_literal: true

require "test_helper"

class CliPlaidAccountsTest < Minitest::Test
  def setup
    LunchMoneyApp::Cache.new(":memory:")
    LunchMoneyApp::Cli::Main.stubs(:setup_from_config!)

    @sdk_api = mock("plaid_accounts_api")
    LunchMoney::PlaidAccountsApi.stubs(:new).returns(@sdk_api)
  end

  def test_list_json
    response = stub(plaid_accounts: [stub(id: 1, to_hash: { "id" => 1, "name" => "Chase Checking" })],
                    to_hash: [{ "id" => 1, "name" => "Chase Checking" }])
    @sdk_api.expects(:get_all_plaid_accounts).returns(response)
    out = capture_stdout { LunchMoneyApp::Cli::PlaidAccounts.start(%w[list --json]) }
    parsed = JSON.parse(out)
    assert_equal "Chase Checking", parsed[0]["name"]
  end

  def test_list_human
    response = stub(
      plaid_accounts: [stub(id: 1, to_hash: { "id" => 1, "name" => "Chase Checking", "type" => "depository", "status" => "active" })],
      to_hash: [{ "id" => 1, "name" => "Chase Checking", "type" => "depository", "status" => "active" }]
    )
    @sdk_api.expects(:get_all_plaid_accounts).returns(response)
    out = capture_stdout { LunchMoneyApp::Cli::PlaidAccounts.start(%w[list]) }
    assert_includes out, "Chase Checking"
  end

  def test_show_json
    account = stub(id: 1, to_hash: { "id" => 1, "name" => "Chase Checking" })
    @sdk_api.expects(:get_plaid_account_by_id).with(1).returns(account)
    out = capture_stdout { LunchMoneyApp::Cli::PlaidAccounts.start(%w[show 1 --json]) }
    assert_equal 1, JSON.parse(out)["id"]
  end

  def test_fetch
    @sdk_api.expects(:trigger_plaid_account_fetch).returns(nil)
    out = capture_stdout { LunchMoneyApp::Cli::PlaidAccounts.start(%w[fetch]) }
    assert_includes out, "triggered"
  end

  def test_fetch_json
    @sdk_api.expects(:trigger_plaid_account_fetch).returns(nil)
    out = capture_stdout { LunchMoneyApp::Cli::PlaidAccounts.start(%w[fetch --json]) }
    parsed = JSON.parse(out)
    assert_equal true, parsed["triggered"]
  end
end
