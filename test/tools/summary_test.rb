# frozen_string_literal: true

require "test_helper"

class SummaryToolsTest < Minitest::Test
  def setup
    @client = mock("client")
    @server = LunchMoneyMcp::Server.new(@client)
    LunchMoneyMcp::Tools::Summary.register(@server)
  end

  def test_registers_get_budget_summary
    assert @server.tool_registered?("get_budget_summary")
  end

  def test_get_budget_summary_required_params
    params = { "start_date" => "2025-01-01", "end_date" => "2025-01-31" }
    @client.expects(:get).with("/budgets", params).returns({ "budget_monthly" => [] })
    result = @server.call_tool("get_budget_summary", params)
    assert result[:content][0][:text]
  end

  def test_get_budget_summary_with_options
    params = {
      "start_date"                   => "2025-01-01",
      "end_date"                     => "2025-01-31",
      "include_totals"               => true,
      "include_rollover_pool"        => true,
      "include_exclude_from_budgets" => false
    }
    @client.expects(:get).with("/budgets", params).returns({})
    @server.call_tool("get_budget_summary", params)
  end

  def test_get_budget_summary_returns_text_response
    @client.stubs(:get).returns({ "data" => [] })
    result = @server.call_tool("get_budget_summary", {
      "start_date" => "2025-01-01", "end_date" => "2025-01-31"
    })
    assert_equal "text", result[:content][0][:type]
  end
end
