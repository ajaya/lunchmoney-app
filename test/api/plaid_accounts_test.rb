# frozen_string_literal: true

require "test_helper"

class ApiPlaidAccountsTest < Minitest::Test
  def setup
    LunchMoneyApp::Cache.new(":memory:")

    @sdk_api = mock("plaid_accounts_api")
    LunchMoney::PlaidAccountsApi.stubs(:new).returns(@sdk_api)
  end

  def test_list
    response = stub(plaid_accounts: [], to_hash: { plaid_accounts: [] })
    @sdk_api.expects(:get_all_plaid_accounts).returns(response)
    result = LunchMoneyApp::Api::PlaidAccounts.list
    assert_equal response, result
  end

  def test_get
    account = stub(id: 1, to_hash: { "id" => 1, "name" => "Chase" })
    @sdk_api.expects(:get_plaid_account_by_id).with(1).returns(account)
    result = LunchMoneyApp::Api::PlaidAccounts.get(1)
    assert_equal account, result
  end

  def test_fetch_no_params
    @sdk_api.expects(:trigger_plaid_account_fetch).returns(nil)
    LunchMoneyApp::Api::PlaidAccounts.fetch
  end

  def test_fetch_with_dates
    @sdk_api.expects(:trigger_plaid_account_fetch)
            .with(start_date: "2025-01-01", end_date: "2025-01-31").returns(nil)
    LunchMoneyApp::Api::PlaidAccounts.fetch(start_date: "2025-01-01", end_date: "2025-01-31")
  end

  def test_fetch_with_id
    @sdk_api.expects(:trigger_plaid_account_fetch).with(id: 5).returns(nil)
    LunchMoneyApp::Api::PlaidAccounts.fetch(id: 5)
  end
end
