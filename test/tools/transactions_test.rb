# frozen_string_literal: true

require "test_helper"

class TransactionsToolsTest < Minitest::Test
  def setup
    @client = mock("client")
    @server = LunchMoneyMcp::Server.new(@client)
    LunchMoneyMcp::Tools::Transactions.register(@server)
  end

  def test_registers_all_tools
    expected = %w[
      get_all_transactions get_transaction create_transactions update_transaction
      delete_transaction delete_transactions update_transactions split_transaction
      unsplit_transaction group_transactions ungroup_transaction
      attach_file get_attachment_url delete_attachment
    ]
    expected.each { |n| assert @server.tool_registered?(n), "Expected #{n} to be registered" }
  end

  def test_get_all_transactions_no_params
    @client.expects(:get).with("/transactions", {}).returns({ "transactions" => [] })
    result = @server.call_tool("get_all_transactions", {})
    assert result[:content][0][:text]
  end

  def test_get_all_transactions_with_filters
    @client.expects(:get).with("/transactions", { "start_date" => "2025-01-01", "limit" => 50 })
           .returns({ "transactions" => [] })
    @server.call_tool("get_all_transactions", { "start_date" => "2025-01-01", "limit" => 50 })
  end

  def test_get_transaction
    txn = { "id" => 42, "payee" => "Coffee Shop" }
    @client.expects(:get).with("/transactions/42").returns(txn)
    result = @server.call_tool("get_transaction", { "id" => 42 })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal "Coffee Shop", parsed["payee"]
  end

  def test_create_transactions
    transactions = [{ "date" => "2025-01-15", "amount" => "12.50", "payee" => "Cafe" }]
    @client.expects(:post).with("/transactions", { "transactions" => transactions })
           .returns({ "ids" => [1] })
    result = @server.call_tool("create_transactions", { "transactions" => transactions })
    assert result[:content][0][:text]
  end

  def test_update_transaction
    @client.expects(:put).with("/transactions/1", { transaction: { "payee" => "Updated" } })
           .returns({ "id" => 1 })
    @server.call_tool("update_transaction", { "id" => 1, "payee" => "Updated" })
  end

  def test_delete_transaction
    @client.expects(:delete).with("/transactions/5").returns(nil)
    result = @server.call_tool("delete_transaction", { "id" => 5 })
    assert_includes result[:content][0][:text], "5"
    assert_includes result[:content][0][:text], "deleted"
  end

  def test_delete_transactions_bulk
    @client.expects(:delete).with("/transactions", { ids: [1, 2, 3] }).returns(nil)
    result = @server.call_tool("delete_transactions", { "ids" => [1, 2, 3] })
    assert_includes result[:content][0][:text], "3 transaction"
  end

  def test_update_transactions_bulk
    txns = [{ "id" => 1, "payee" => "New" }]
    @client.expects(:put).with("/transactions", { "transactions" => txns }).returns({})
    @server.call_tool("update_transactions", { "transactions" => txns })
  end

  def test_split_transaction
    splits = [{ "amount" => "5.00" }, { "amount" => "7.50" }]
    @client.expects(:post).with("/transactions/10/split", { child_transactions: splits })
           .returns({ "children" => [] })
    @server.call_tool("split_transaction", { "id" => 10, "child_transactions" => splits })
  end

  def test_unsplit_transaction
    @client.expects(:post).with("/transactions/unsplit", { parent_id: 10 }).returns(nil)
    result = @server.call_tool("unsplit_transaction", { "id" => 10 })
    assert_includes result[:content][0][:text], "unsplit"
  end

  def test_group_transactions
    body = { "ids" => [1, 2], "date" => "2025-01-15", "payee" => "Dinner" }
    @client.expects(:post).with("/transactions/group", body).returns({ "id" => 99 })
    @server.call_tool("group_transactions", body)
  end

  def test_ungroup_transaction
    @client.expects(:delete).with("/transactions/group/99").returns(nil)
    result = @server.call_tool("ungroup_transaction", { "id" => 99 })
    assert_includes result[:content][0][:text], "ungrouped"
  end

  def test_attach_file
    @client.expects(:post).with("/transactions/1/attachments", { "file" => "base64data" })
           .returns({ "id" => 10 })
    @server.call_tool("attach_file", { "transaction_id" => 1, "file" => "base64data" })
  end

  def test_get_attachment_url
    @client.expects(:get).with("/transactions/attachments/10").returns({ "url" => "https://example.com" })
    result = @server.call_tool("get_attachment_url", { "file_id" => 10 })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal "https://example.com", parsed["url"]
  end

  def test_delete_attachment
    @client.expects(:delete).with("/transactions/attachments/10").returns(nil)
    result = @server.call_tool("delete_attachment", { "file_id" => 10 })
    assert_includes result[:content][0][:text], "deleted"
  end
end
