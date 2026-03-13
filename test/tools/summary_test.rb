# frozen_string_literal: true

require "test_helper"

class SummaryToolsTest < Minitest::Test
  def setup
    @server = build_server
    LunchMoneyApp::Tools::Summary.register(@server)

    @sdk_api = mock("summary_api")
    LunchMoney::SummaryApi.stubs(:new).returns(@sdk_api)
  end

  def test_registers_get_budget_summary
    assert @server.tools.key?("get_budget_summary")
  end

  def test_get_budget_summary_required_params
    @sdk_api.expects(:get_budget_summary).with("2025-01-01", "2025-01-31").returns({ "budget_monthly" => [] })
    result = call_tool(@server, "get_budget_summary", { start_date: "2025-01-01", end_date: "2025-01-31" })
    assert result[:content][0][:text]
  end

  def test_get_budget_summary_with_options
    @sdk_api.expects(:get_budget_summary).with("2025-01-01", "2025-01-31",
      include_totals: true, include_rollover_pool: true, include_exclude_from_budgets: false
    ).returns({})
    call_tool(@server, "get_budget_summary", {
      start_date: "2025-01-01", end_date: "2025-01-31",
      include_totals: true, include_rollover_pool: true,
      include_exclude_from_budgets: false
    })
  end

  def test_get_budget_summary_returns_text_response
    @sdk_api.stubs(:get_budget_summary).returns({ "data" => [] })
    result = call_tool(@server, "get_budget_summary", { start_date: "2025-01-01", end_date: "2025-01-31" })
    assert_equal "text", result[:content][0][:type]
  end
end
