# frozen_string_literal: true

require "test_helper"

class RecurringItemsToolsTest < Minitest::Test
  def setup
    @server = build_server
    LunchMoneyApp::Tools::RecurringItems.register(@server)

    @sdk_api = mock("recurring_items_api")
    LunchMoney::RecurringItemsApi.stubs(:new).returns(@sdk_api)
  end

  def test_registers_all_tools
    %w[get_all_recurring_items get_recurring_item].each do |name|
      assert @server.tools.key?(name), "Expected #{name} to be registered"
    end
  end

  def test_get_all_recurring_items_no_params
    response = stub(recurring_items: nil, recurring_expenses: [], to_hash: { "recurring_expenses" => [] })
    @sdk_api.expects(:get_all_recurring).returns(response)
    result = call_tool(@server, "get_all_recurring_items")
    assert result[:content][0][:text]
  end

  def test_get_all_recurring_items_with_dates
    response = stub(recurring_items: nil, recurring_expenses: [], to_hash: {})
    @sdk_api.expects(:get_all_recurring).returns(response)
    call_tool(@server, "get_all_recurring_items", { start_date: "2025-01-01", end_date: "2025-03-31" })
  end

  def test_get_recurring_item
    item = stub(id: 1, to_hash: { "id" => 1, "payee" => "Netflix" })
    @sdk_api.expects(:get_recurring_by_id).with(1).returns(item)
    result = call_tool(@server, "get_recurring_item", { id: 1 })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal "Netflix", parsed["payee"]
  end
end
