# frozen_string_literal: true

require "test_helper"

class CliTransactionsTest < Minitest::Test
  def setup
    LunchMoneyApp::Cache.new(":memory:")
    LunchMoneyApp::Cli::Main.stubs(:setup_from_config!)

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

  def test_list_json_output
    response = stub(transactions: [stub(id: 1, to_hash: { "id" => 1, "payee" => "Coffee" })],
                    to_hash: { "transactions" => [{ "id" => 1, "payee" => "Coffee" }] })
    @bulk_api.expects(:get_all_transactions).returns(response)
    out = capture_stdout { LunchMoneyApp::Cli::Transactions.start(%w[list --json]) }
    parsed = JSON.parse(out)
    assert_equal 1, parsed["transactions"][0]["id"]
  end

  def test_list_human_output
    response = stub(
      transactions: [stub(id: 1, to_hash: { "id" => 1, "date" => "2025-01-15", "payee" => "Coffee", "amount" => "4.50", "status" => "reviewed" })],
      to_hash: { "transactions" => [{ "id" => 1, "date" => "2025-01-15", "payee" => "Coffee", "amount" => "4.50", "status" => "reviewed" }] }
    )
    @bulk_api.expects(:get_all_transactions).returns(response)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[transactions list]) }
    assert_includes out, "Coffee"
    assert_includes out, "4.50"
  end

  def test_list_with_filters
    response = stub(transactions: [], to_hash: { "transactions" => [] })
    @bulk_api.expects(:get_all_transactions).returns(response)
    capture_stdout { LunchMoneyApp::Cli::Main.start(%w[transactions list --start-date 2025-01-01 --limit 10]) }
  end

  def test_show_json
    txn = stub(id: 42, to_hash: { "id" => 42, "payee" => "Shop" })
    @api.expects(:get_transaction_by_id).with(42).returns(txn)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[transactions show 42 --json]) }
    assert_equal "Shop", JSON.parse(out)["payee"]
  end

  def test_delete
    @api.expects(:delete_transaction_by_id).with(5).returns(nil)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[transactions delete 5]) }
    assert_includes out, "deleted"
  end

  def test_delete_json
    @api.expects(:delete_transaction_by_id).with(5).returns(nil)
    out = capture_stdout { LunchMoneyApp::Cli::Transactions.start(%w[delete 5 --json]) }
    parsed = JSON.parse(out)
    assert_equal true, parsed["deleted"]
  end

  def test_unsplit
    @split_api.expects(:unsplit_transaction).with(10).returns(nil)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[transactions unsplit 10]) }
    assert_includes out, "unsplit"
  end

  def test_ungroup
    @group_api.expects(:ungroup_transactions).with(99).returns(nil)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[transactions ungroup 99]) }
    assert_includes out, "ungrouped"
  end

  def test_create
    @bulk_api.expects(:create_new_transactions).returns({ "ids" => [100, 101] })
    out = capture_stdout do
      LunchMoneyApp::Cli::Transactions.start(%w[create --data [{"amount":"12.50","payee":"Test"}]])
    end
    assert_includes out, "2 transaction(s)"
  end

  def test_create_json
    @bulk_api.expects(:create_new_transactions).returns({ "ids" => [100] })
    out = capture_stdout do
      LunchMoneyApp::Cli::Transactions.start(%w[create --data [{"amount":"5.00"}] --json])
    end
    parsed = JSON.parse(out)
    assert_equal [100], parsed["ids"]
  end

  def test_update
    @api.expects(:update_transaction).with(7, { "payee" => "NewPayee" }).returns({ "id" => 7 })
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[transactions update 7 --payee NewPayee]) }
    assert_includes out, "updated"
  end

  def test_update_json
    @api.expects(:update_transaction).with(7, { "payee" => "NewPayee" }).returns({ "id" => 7 })
    out = capture_stdout { LunchMoneyApp::Cli::Transactions.start(%w[update 7 --payee NewPayee --json]) }
    parsed = JSON.parse(out)
    assert_equal 7, parsed["id"]
  end

  def test_delete_bulk
    @bulk_api.expects(:delete_transactions).returns(nil)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[transactions delete_bulk 1 2 3]) }
    assert_includes out, "3 transaction(s) deleted"
  end

  def test_delete_bulk_json
    @bulk_api.expects(:delete_transactions).returns(nil)
    out = capture_stdout { LunchMoneyApp::Cli::Transactions.start(%w[delete_bulk 1 2 --json]) }
    parsed = JSON.parse(out)
    assert_equal true, parsed["deleted"]
    assert_equal [1, 2], parsed["ids"]
  end

  def test_split
    @split_api.expects(:split_transaction).returns({ "children" => [10, 11] })
    out = capture_stdout do
      LunchMoneyApp::Cli::Main.start(%w[transactions split 5 --data [{"amount":"3.00"},{"amount":"9.50"}]])
    end
    assert_includes out, "split"
  end

  def test_split_json
    @split_api.expects(:split_transaction).returns({ "children" => [10, 11] })
    out = capture_stdout do
      LunchMoneyApp::Cli::Transactions.start(%w[split 5 --data [{"amount":"3.00"},{"amount":"9.50"}] --json])
    end
    parsed = JSON.parse(out)
    assert_equal [10, 11], parsed["children"]
  end

  def test_group
    @group_api.expects(:group_transactions).returns({ "id" => 200 })
    out = capture_stdout do
      LunchMoneyApp::Cli::Main.start(%w[transactions group --data {"ids":[1,2],"date":"2025-01-15","payee":"Dinner"}])
    end
    assert_includes out, "grouped"
  end

  def test_group_json
    @group_api.expects(:group_transactions).returns({ "id" => 200 })
    out = capture_stdout do
      LunchMoneyApp::Cli::Transactions.start(%w[group --data {"ids":[1,2],"date":"2025-01-15","payee":"Dinner"} --json])
    end
    parsed = JSON.parse(out)
    assert_equal 200, parsed["id"]
  end
end
