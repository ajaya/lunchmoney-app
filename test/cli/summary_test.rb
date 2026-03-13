# frozen_string_literal: true

require "test_helper"

class CliSummaryTest < Minitest::Test
  def setup
    LunchMoneyApp::Cache.new(":memory:")
    LunchMoneyApp::Cli::Main.stubs(:setup_from_config!)

    @sdk_api = mock("summary_api")
    LunchMoney::SummaryApi.stubs(:new).returns(@sdk_api)
  end

  def test_budget_json
    response = [{ "category_name" => "Food", "budget_amount" => "500.00", "spending_to_base" => "350.00" }]
    @sdk_api.expects(:get_budget_summary).with("2025-01-01", "2025-01-31").returns(response)
    out = capture_stdout { LunchMoneyApp::Cli::Summary.start(%w[budget --start-date 2025-01-01 --end-date 2025-01-31 --json]) }
    parsed = JSON.parse(out)
    assert_equal "Food", parsed[0]["category_name"]
  end

  def test_budget_human
    response = [{ "category_name" => "Food", "budget_amount" => "500.00", "spending_to_base" => "350.00" }]
    @sdk_api.expects(:get_budget_summary).with("2025-01-01", "2025-01-31").returns(response)
    out = capture_stdout { LunchMoneyApp::Cli::Summary.start(%w[budget --start-date 2025-01-01 --end-date 2025-01-31]) }
    assert_includes out, "Food"
    assert_includes out, "500.00"
  end

  def test_budget_via_main
    response = [{ "category_name" => "Transport", "budget_amount" => "200.00" }]
    @sdk_api.expects(:get_budget_summary).with("2025-03-01", "2025-03-31").returns(response)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[summary budget --start-date 2025-03-01 --end-date 2025-03-31]) }
    assert_includes out, "Transport"
  end

  def test_budget_with_options
    response = []
    @sdk_api.expects(:get_budget_summary).with("2025-01-01", "2025-01-31", include_totals: true).returns(response)
    out = capture_stdout { LunchMoneyApp::Cli::Summary.start(%w[budget --start-date 2025-01-01 --end-date 2025-01-31 --include-totals]) }
    assert_includes out, "No budget data"
  end
end
