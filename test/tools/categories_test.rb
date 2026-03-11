# frozen_string_literal: true

require "test_helper"

class CategoriesToolsTest < Minitest::Test
  def setup
    @client = mock("client")
    @server = LunchMoneyMcp::Server.new(@client)
    LunchMoneyMcp::Tools::Categories.register(@server)
  end

  def test_registers_all_tools
    %w[get_all_categories get_category create_category update_category delete_category].each do |name|
      assert @server.tool_registered?(name), "Expected #{name} to be registered"
    end
  end

  def test_get_all_categories_no_params
    @client.expects(:get).with("/categories", {}).returns([])
    result = @server.call_tool("get_all_categories", {})
    assert_equal "[]", result[:content][0][:text]
  end

  def test_get_all_categories_with_format
    @client.expects(:get).with("/categories", { "format" => "nested" }).returns([])
    @server.call_tool("get_all_categories", { "format" => "nested" })
  end

  def test_get_category
    category = { "id" => 1, "name" => "Food" }
    @client.expects(:get).with("/categories/1").returns(category)
    result = @server.call_tool("get_category", { "id" => 1 })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal "Food", parsed["name"]
  end

  def test_create_category
    @client.expects(:post).with("/categories", { "name" => "Transport" }).returns({ "id" => 2 })
    result = @server.call_tool("create_category", { "name" => "Transport" })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal 2, parsed["id"]
  end

  def test_create_category_with_optional_fields
    body = { "name" => "Savings", "is_income" => false, "exclude_from_budget" => true }
    @client.expects(:post).with("/categories", body).returns({ "id" => 3 })
    @server.call_tool("create_category", body)
  end

  def test_update_category
    @client.expects(:put).with("/categories/5", { "name" => "Groceries" }).returns({ "id" => 5 })
    result = @server.call_tool("update_category", { "id" => 5, "name" => "Groceries" })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal 5, parsed["id"]
  end

  def test_delete_category_returns_confirmation
    @client.expects(:delete).with("/categories/7", {}).returns(nil)
    result = @server.call_tool("delete_category", { "id" => 7 })
    assert_includes result[:content][0][:text], "7"
    assert_includes result[:content][0][:text], "deleted"
  end

  def test_delete_category_with_force
    @client.expects(:delete).with("/categories/7", { force: true }).returns(nil)
    @server.call_tool("delete_category", { "id" => 7, "force" => true })
  end
end
