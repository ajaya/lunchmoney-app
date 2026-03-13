# frozen_string_literal: true

require "test_helper"

class CliManualAccountsTest < Minitest::Test
  def setup
    LunchMoneyApp::Cache.new(":memory:")
    LunchMoneyApp::Cli::Main.stubs(:setup_from_config!)

    @sdk_api = mock("manual_accounts_api")
    LunchMoney::ManualAccountsApi.stubs(:new).returns(@sdk_api)
  end

  def test_list_json
    response = stub(
      manual_accounts: [stub(id: 1, to_hash: { "id" => 1, "name" => "Savings" })],
      to_hash: [{ "id" => 1, "name" => "Savings" }]
    )
    @sdk_api.expects(:get_all_manual_accounts).returns(response)
    out = capture_stdout { LunchMoneyApp::Cli::ManualAccounts.start(%w[list --json]) }
    parsed = JSON.parse(out)
    assert_equal "Savings", parsed[0]["name"]
  end

  def test_list_human
    response = stub(
      manual_accounts: [stub(id: 1, to_hash: { "id" => 1, "name" => "Savings", "type" => "cash", "balance" => "500.00" })],
      to_hash: [{ "id" => 1, "name" => "Savings", "type" => "cash", "balance" => "500.00" }]
    )
    @sdk_api.expects(:get_all_manual_accounts).returns(response)
    out = capture_stdout { LunchMoneyApp::Cli::ManualAccounts.start(%w[list]) }
    assert_includes out, "Savings"
    assert_includes out, "500.00"
  end

  def test_show_json
    account = stub(id: 1, to_hash: { "id" => 1, "name" => "Savings" })
    @sdk_api.expects(:get_manual_account_by_id).with(1).returns(account)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[manual_accounts show 1 --json]) }
    assert_equal 1, JSON.parse(out)["id"]
  end

  def test_create
    @sdk_api.expects(:create_manual_account).returns({ "id" => 2, "name" => "Cash Stash" })
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[manual_accounts create --name Cash\ Stash --type cash --balance 100.00]) }
    assert_includes out, "Cash Stash"
  end

  def test_create_json
    @sdk_api.expects(:create_manual_account).returns({ "id" => 2, "name" => "Cash Stash" })
    out = capture_stdout { LunchMoneyApp::Cli::ManualAccounts.start(%w[create --name Cash\ Stash --type cash --balance 100.00 --json]) }
    parsed = JSON.parse(out)
    assert_equal 2, parsed["id"]
  end

  def test_update
    @sdk_api.expects(:update_manual_account).with(3, { "balance" => "200.00" }).returns({ "id" => 3 })
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[manual_accounts update 3 --balance 200.00]) }
    assert_includes out, "updated"
  end

  def test_delete
    @sdk_api.expects(:delete_manual_account).with(4, delete_items: false, delete_balance_history: false).returns(nil)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[manual_accounts delete 4]) }
    assert_includes out, "deleted"
  end

  def test_delete_json
    @sdk_api.expects(:delete_manual_account).with(4, delete_items: false, delete_balance_history: false).returns(nil)
    out = capture_stdout { LunchMoneyApp::Cli::ManualAccounts.start(%w[delete 4 --json]) }
    parsed = JSON.parse(out)
    assert_equal true, parsed["deleted"]
  end

  def test_delete_with_options
    @sdk_api.expects(:delete_manual_account).with(4, delete_items: true, delete_balance_history: true).returns(nil)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[manual_accounts delete 4 --delete-items --delete-balance-history]) }
    assert_includes out, "deleted"
  end
end
