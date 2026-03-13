# frozen_string_literal: true

require "test_helper"

class TransactionsToolsTest < Minitest::Test
  def setup
    @server = build_server
    LunchMoneyApp::Tools::Transactions.register(@server)

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

  def test_registers_all_tools
    expected = %w[
      get_all_transactions get_transaction create_transactions update_transaction
      delete_transaction delete_transactions update_transactions split_transaction
      unsplit_transaction group_transactions ungroup_transaction
      attach_file get_attachment_url delete_attachment
    ]
    expected.each { |n| assert @server.tools.key?(n), "Expected #{n} to be registered" }
  end

  def test_get_all_transactions_no_params
    response = stub(transactions: [], to_hash: { "transactions" => [] })
    @bulk_api.expects(:get_all_transactions).returns(response)
    result = call_tool(@server, "get_all_transactions")
    assert result[:content][0][:text]
  end

  def test_get_all_transactions_with_filters
    response = stub(transactions: [], to_hash: { "transactions" => [] })
    @bulk_api.expects(:get_all_transactions).with(start_date: "2025-01-01", limit: 50).returns(response)
    call_tool(@server, "get_all_transactions", { start_date: "2025-01-01", limit: 50 })
  end

  def test_get_transaction
    txn = stub(id: 42, to_hash: { "id" => 42, "payee" => "Coffee Shop" })
    @api.expects(:get_transaction_by_id).with(42).returns(txn)
    result = call_tool(@server, "get_transaction", { id: 42 })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal "Coffee Shop", parsed["payee"]
  end

  def test_create_transactions
    @bulk_api.expects(:create_new_transactions).returns({ "ids" => [1] })
    result = call_tool(@server, "create_transactions", { transactions: [{ "amount" => "12.50" }] })
    assert result[:content][0][:text]
  end

  def test_update_transaction
    @api.expects(:update_transaction).with(1, { "payee" => "Updated" }).returns({ "id" => 1 })
    call_tool(@server, "update_transaction", { id: 1, payee: "Updated" })
  end

  def test_delete_transaction
    @api.expects(:delete_transaction_by_id).with(5).returns(nil)
    result = call_tool(@server, "delete_transaction", { id: 5 })
    assert_includes result[:content][0][:text], "5"
    assert_includes result[:content][0][:text], "deleted"
  end

  def test_delete_transactions_bulk
    @bulk_api.expects(:delete_transactions).returns(nil)
    result = call_tool(@server, "delete_transactions", { ids: [1, 2, 3] })
    assert_includes result[:content][0][:text], "3 transaction"
  end

  def test_update_transactions_bulk
    @bulk_api.expects(:update_transactions).returns({})
    call_tool(@server, "update_transactions", { transactions: [{ "id" => 1, "payee" => "New" }] })
  end

  def test_split_transaction
    @split_api.expects(:split_transaction).returns({ "children" => [] })
    call_tool(@server, "split_transaction", { id: 10, child_transactions: [{ "amount" => "5.00" }, { "amount" => "7.50" }] })
  end

  def test_unsplit_transaction
    @split_api.expects(:unsplit_transaction).with(10).returns(nil)
    result = call_tool(@server, "unsplit_transaction", { id: 10 })
    assert_includes result[:content][0][:text], "unsplit"
  end

  def test_group_transactions
    @group_api.expects(:group_transactions).returns({ "id" => 99 })
    call_tool(@server, "group_transactions", { ids: [1, 2], date: "2025-01-15", payee: "Dinner" })
  end

  def test_ungroup_transaction
    @group_api.expects(:ungroup_transactions).with(99).returns(nil)
    result = call_tool(@server, "ungroup_transaction", { id: 99 })
    assert_includes result[:content][0][:text], "ungrouped"
  end

  def test_attach_file
    @files_api.expects(:attach_file_to_transaction).returns({ "id" => 10 })
    call_tool(@server, "attach_file", { transaction_id: 1, file: "base64data" })
  end

  def test_get_attachment_url
    @files_api.expects(:get_transaction_attachment_url).with(10).returns({ "url" => "https://example.com" })
    result = call_tool(@server, "get_attachment_url", { file_id: 10 })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal "https://example.com", parsed["url"]
  end

  def test_delete_attachment
    @files_api.expects(:delete_transaction_attachment).with(10).returns(nil)
    result = call_tool(@server, "delete_attachment", { file_id: 10 })
    assert_includes result[:content][0][:text], "deleted"
  end
end
