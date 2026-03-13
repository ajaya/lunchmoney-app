# frozen_string_literal: true

require "test_helper"

class ApiCategoriesTest < Minitest::Test
  def setup
    LunchMoneyApp::Cache.new(":memory:")

    @sdk_api = mock("categories_api")
    LunchMoney::CategoriesApi.stubs(:new).returns(@sdk_api)
  end

  def test_list_no_params
    response = stub(categories: [], to_hash: { "categories" => [] })
    @sdk_api.expects(:get_all_categories).returns(response)
    result = LunchMoneyApp::Api::Categories.list
    assert_equal response, result
  end

  def test_list_with_format
    response = stub(categories: [], to_hash: { "categories" => [] })
    @sdk_api.expects(:get_all_categories).with(format: "nested").returns(response)
    LunchMoneyApp::Api::Categories.list({ "format" => "nested" })
  end

  def test_list_with_is_group
    response = stub(categories: [], to_hash: { "categories" => [] })
    @sdk_api.expects(:get_all_categories).with(is_group: true).returns(response)
    LunchMoneyApp::Api::Categories.list({ "is_group" => true })
  end

  def test_get
    category = stub(id: 1, to_hash: { "id" => 1, "name" => "Food" })
    @sdk_api.expects(:get_category_by_id).with(1).returns(category)
    result = LunchMoneyApp::Api::Categories.get(1)
    assert_equal category, result
  end

  def test_get_caches_category
    category = stub(id: 1, to_hash: { "id" => 1, "name" => "Food" })
    @sdk_api.expects(:get_category_by_id).with(1).returns(category)
    LunchMoneyApp::Api::Categories.get(1)
    assert_equal({ "id" => 1, "name" => "Food" }, LunchMoneyApp::Api::Categories.cached(1))
  end

  def test_create
    @sdk_api.expects(:create_category).returns({ "id" => 2 })
    result = LunchMoneyApp::Api::Categories.create({ "name" => "Transport" })
    assert_equal({ "id" => 2 }, result)
  end

  def test_update
    @sdk_api.expects(:update_category).with(1, { "name" => "Groceries" }).returns({ "id" => 1 })
    LunchMoneyApp::Api::Categories.update(1, { "name" => "Groceries" })
  end

  def test_delete
    @sdk_api.expects(:delete_category).with(1, {}).returns(nil)
    LunchMoneyApp::Api::Categories.delete(1)
  end

  def test_delete_with_force
    @sdk_api.expects(:delete_category).with(1, { force: true }).returns(nil)
    LunchMoneyApp::Api::Categories.delete(1, force: true)
  end
end
