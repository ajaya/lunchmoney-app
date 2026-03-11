# frozen_string_literal: true

require "test_helper"

class RecurringItemsToolsTest < Minitest::Test
  def setup
    @client = mock("client")
    @server = LunchMoneyMcp::Server.new(@client)
    LunchMoneyMcp::Tools::RecurringItems.register(@server)
  end

  def test_registers_all_tools
    %w[get_all_recurring_items get_recurring_item].each do |name|
      assert @server.tool_registered?(name), "Expected #{name} to be registered"
    end
  end

  def test_get_all_recurring_items_no_params
    @client.expects(:get).with("/recurring_expenses", {}).returns({ "recurring_expenses" => [] })
    result = @server.call_tool("get_all_recurring_items", {})
    assert result[:content][0][:text]
  end

  def test_get_all_recurring_items_with_dates
    params = { "start_date" => "2025-01-01", "end_date" => "2025-03-31" }
    @client.expects(:get).with("/recurring_expenses", params).returns({})
    @server.call_tool("get_all_recurring_items", params)
  end

  def test_get_all_recurring_items_with_suggested
    params = { "include_suggested" => true }
    @client.expects(:get).with("/recurring_expenses", params).returns({})
    @server.call_tool("get_all_recurring_items", params)
  end

  def test_get_recurring_item
    item = { "id" => 1, "payee" => "Netflix" }
    @client.expects(:get).with("/recurring_expenses/1").returns(item)
    result = @server.call_tool("get_recurring_item", { "id" => 1 })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal "Netflix", parsed["payee"]
  end
end
