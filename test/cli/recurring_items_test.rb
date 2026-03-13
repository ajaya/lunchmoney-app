# frozen_string_literal: true

require "test_helper"

class CliRecurringItemsTest < Minitest::Test
  def setup
    LunchMoneyApp::Cache.new(":memory:")
    LunchMoneyApp::Cli::Main.stubs(:setup_from_config!)

    @sdk_api = mock("recurring_items_api")
    LunchMoney::RecurringItemsApi.stubs(:new).returns(@sdk_api)
  end

  def test_list_json
    response = stub(
      recurring_items: [stub(id: 1, to_hash: { "id" => 1, "payee" => "Netflix" })],
      to_hash: { "recurring_expenses" => [{ "id" => 1, "payee" => "Netflix" }] }
    )
    @sdk_api.expects(:get_all_recurring).returns(response)
    out = capture_stdout { LunchMoneyApp::Cli::RecurringItems.start(%w[list --json]) }
    parsed = JSON.parse(out)
    assert_equal "Netflix", parsed["recurring_expenses"][0]["payee"]
  end

  def test_list_human
    response = stub(
      recurring_items: [stub(id: 1, to_hash: { "id" => 1, "payee" => "Netflix", "amount" => "15.99", "cadence" => "monthly" })],
      to_hash: { "recurring_expenses" => [{ "id" => 1, "payee" => "Netflix", "amount" => "15.99", "cadence" => "monthly" }] }
    )
    @sdk_api.expects(:get_all_recurring).returns(response)
    out = capture_stdout { LunchMoneyApp::Cli::RecurringItems.start(%w[list]) }
    assert_includes out, "Netflix"
    assert_includes out, "15.99"
  end

  def test_list_with_filters
    response = stub(recurring_items: [], to_hash: { "recurring_expenses" => [] })
    @sdk_api.expects(:get_all_recurring).returns(response)
    capture_stdout { LunchMoneyApp::Cli::Main.start(%w[recurring_items list --start-date 2025-01-01 --end-date 2025-12-31]) }
  end

  def test_show_json
    item = stub(id: 1, to_hash: { "id" => 1, "payee" => "Netflix" })
    @sdk_api.expects(:get_recurring_by_id).with(1).returns(item)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[recurring_items show 1 --json]) }
    assert_equal "Netflix", JSON.parse(out)["payee"]
  end

  def test_show_with_dates
    item = stub(id: 1, to_hash: { "id" => 1, "payee" => "Netflix" })
    @sdk_api.expects(:get_recurring_by_id).with(1, start_date: "2025-01-01", end_date: "2025-06-01").returns(item)
    capture_stdout { LunchMoneyApp::Cli::Main.start(%w[recurring_items show 1 --start-date 2025-01-01 --end-date 2025-06-01 --json]) }
  end
end
