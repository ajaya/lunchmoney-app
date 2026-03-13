# frozen_string_literal: true

require "test_helper"

class ApiTransactionsTest < Minitest::Test
  def setup
    LunchMoneyApp::Cache.new(":memory:")

    @bulk_api  = mock("bulk_api")
    @api       = mock("api")
    @split_api = mock("split_api")
    @group_api = mock("group_api")
    @files_api = mock("files_api")
    LunchMoney::TransactionsBulkApi.stubs(:new).returns(@bulk_api)
    LunchMoney::TransactionsApi.stubs(:new).returns(@api)
    LunchMoney::TransactionsSplitApi.stubs(:new).returns(@split_api)
    LunchMoney::TransactionsGroupApi.stubs(:new).returns(@group_api)
    LunchMoney::TransactionsFilesApi.stubs(:new).returns(@files_api)
  end

  def test_list_no_params
    response = stub(transactions: [], to_hash: { "transactions" => [] })
    @bulk_api.expects(:get_all_transactions).returns(response)
    result = LunchMoneyApp::Api::Transactions.list
    assert_equal response, result
  end

  def test_list_with_filters
    response = stub(transactions: [], to_hash: { "transactions" => [] })
    @bulk_api.expects(:get_all_transactions).with(start_date: "2025-01-01", limit: 50).returns(response)
    LunchMoneyApp::Api::Transactions.list({ "start_date" => "2025-01-01", "limit" => 50 })
  end

  def test_list_caches_transactions
    txn = stub(id: 1, to_hash: { "id" => 1, "payee" => "Coffee" })
    response = stub(transactions: [txn], to_hash: { "transactions" => [{ "id" => 1 }] })
    @bulk_api.expects(:get_all_transactions).returns(response)
    LunchMoneyApp::Api::Transactions.list
    assert_equal({ "id" => 1, "payee" => "Coffee" }, LunchMoneyApp::Api::Transactions.cached(1))
  end

  def test_get
    txn = stub(id: 42, to_hash: { "id" => 42, "payee" => "Shop" })
    @api.expects(:get_transaction_by_id).with(42).returns(txn)
    result = LunchMoneyApp::Api::Transactions.get(42)
    assert_equal txn, result
  end

  def test_create
    @bulk_api.expects(:create_new_transactions).returns({ "ids" => [1] })
    result = LunchMoneyApp::Api::Transactions.create(transactions: [{ "amount" => "10" }])
    assert_equal({ "ids" => [1] }, result)
  end

  def test_update
    @api.expects(:update_transaction).with(1, { "payee" => "New" }).returns({ "id" => 1 })
    LunchMoneyApp::Api::Transactions.update(1, { "payee" => "New" })
  end

  def test_update_bulk
    @bulk_api.expects(:update_transactions).returns({})
    LunchMoneyApp::Api::Transactions.update_bulk([{ "id" => 1 }])
  end

  def test_delete
    @api.expects(:delete_transaction_by_id).with(1).returns(nil)
    LunchMoneyApp::Api::Transactions.delete(1)
  end

  def test_delete_bulk
    @bulk_api.expects(:delete_transactions).returns(nil)
    LunchMoneyApp::Api::Transactions.delete_bulk([1, 2])
  end

  def test_split
    @split_api.expects(:split_transaction).returns({ "children" => [] })
    LunchMoneyApp::Api::Transactions.split(1, [{ "amount" => "5" }, { "amount" => "7" }])
  end

  def test_unsplit
    @split_api.expects(:unsplit_transaction).with(1).returns(nil)
    LunchMoneyApp::Api::Transactions.unsplit(1)
  end

  def test_group
    @group_api.expects(:group_transactions).returns({ "id" => 99 })
    LunchMoneyApp::Api::Transactions.group(ids: [1, 2], date: "2025-01-01", payee: "Dinner")
  end

  def test_ungroup
    @group_api.expects(:ungroup_transactions).with(99).returns(nil)
    LunchMoneyApp::Api::Transactions.ungroup(99)
  end

  def test_attach_file
    @files_api.expects(:attach_file_to_transaction).returns({ "id" => 10 })
    LunchMoneyApp::Api::Transactions.attach_file(1, file: "data")
  end

  def test_get_attachment_url
    @files_api.expects(:get_transaction_attachment_url).with(10).returns({ "url" => "https://example.com" })
    LunchMoneyApp::Api::Transactions.get_attachment_url(10)
  end

  def test_delete_attachment
    @files_api.expects(:delete_transaction_attachment).with(10).returns(nil)
    LunchMoneyApp::Api::Transactions.delete_attachment(10)
  end
end
