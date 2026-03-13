# frozen_string_literal: true

require "test_helper"

class CategoriesToolsTest < Minitest::Test
  def setup
    @server = build_server
    LunchMoneyApp::Tools::Categories.register(@server)

    @sdk_api = mock("categories_api")
    LunchMoney::CategoriesApi.stubs(:new).returns(@sdk_api)
  end

  def test_registers_all_tools
    %w[get_all_categories get_category create_category update_category delete_category].each do |name|
      assert @server.tools.key?(name), "Expected #{name} to be registered"
    end
  end

  def test_get_all_categories_no_params
    response = stub(categories: [], to_hash: { "categories" => [] })
    @sdk_api.expects(:get_all_categories).returns(response)
    result = call_tool(@server, "get_all_categories")
    assert result[:content][0][:text]
  end

  def test_get_all_categories_with_format
    response = stub(categories: [], to_hash: { "categories" => [] })
    @sdk_api.expects(:get_all_categories).with(format: "nested").returns(response)
    call_tool(@server, "get_all_categories", { format: "nested" })
  end

  def test_get_all_categories_with_is_group
    response = stub(categories: [], to_hash: { "categories" => [] })
    @sdk_api.expects(:get_all_categories).with(is_group: true).returns(response)
    call_tool(@server, "get_all_categories", { is_group: true })
  end

  def test_get_category
    category = stub(id: 1, to_hash: { "id" => 1, "name" => "Food" })
    @sdk_api.expects(:get_category_by_id).with(1).returns(category)
    result = call_tool(@server, "get_category", { id: 1 })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal "Food", parsed["name"]
  end

  def test_create_category
    @sdk_api.expects(:create_category).returns({ "id" => 2 })
    result = call_tool(@server, "create_category", { name: "Transport" })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal 2, parsed["id"]
  end

  def test_create_category_with_optional_fields
    @sdk_api.expects(:create_category).returns({ "id" => 3 })
    call_tool(@server, "create_category", { name: "Savings", is_income: false, exclude_from_budget: true })
  end

  def test_create_category_group_with_children
    @sdk_api.expects(:create_category).returns({ "id" => 4 })
    call_tool(@server, "create_category", { name: "Auto", is_group: true, children: [1, 2] })
  end

  def test_update_category
    @sdk_api.expects(:update_category).with(5, { "name" => "Groceries" }).returns({ "id" => 5 })
    result = call_tool(@server, "update_category", { id: 5, name: "Groceries" })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal 5, parsed["id"]
  end

  def test_update_category_with_children
    @sdk_api.expects(:update_category).with(5, { "children" => [10, 11] }).returns({ "id" => 5 })
    call_tool(@server, "update_category", { id: 5, children: [10, 11] })
  end

  def test_delete_category_returns_confirmation
    @sdk_api.expects(:delete_category).with(7, {}).returns(nil)
    result = call_tool(@server, "delete_category", { id: 7 })
    assert_includes result[:content][0][:text], "7"
    assert_includes result[:content][0][:text], "deleted"
  end

  def test_delete_category_with_force
    @sdk_api.expects(:delete_category).with(7, { force: true }).returns(nil)
    call_tool(@server, "delete_category", { id: 7, force: true })
  end
end
