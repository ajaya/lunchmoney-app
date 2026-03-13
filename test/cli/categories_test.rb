# frozen_string_literal: true

require "test_helper"

class CliCategoriesTest < Minitest::Test
  def setup
    LunchMoneyApp::Cache.new(":memory:")
    LunchMoneyApp::Cli::Main.stubs(:setup_from_config!)

    @sdk_api = mock("categories_api")
    LunchMoney::CategoriesApi.stubs(:new).returns(@sdk_api)
  end

  def test_list_json_output
    response = stub(categories: [stub(id: 1, to_hash: { "id" => 1, "name" => "Food" })],
                    to_hash: { "categories" => [{ "id" => 1, "name" => "Food" }] })
    @sdk_api.expects(:get_all_categories).returns(response)
    out = capture_stdout { LunchMoneyApp::Cli::Categories.start(%w[list --json]) }
    parsed = JSON.parse(out)
    assert_equal 1, parsed["categories"][0]["id"]
  end

  def test_list_human_output
    response = stub(
      categories: [stub(id: 1, to_hash: { "id" => 1, "name" => "Food", "is_group" => false, "archived" => false })],
      to_hash: { "categories" => [{ "id" => 1, "name" => "Food", "is_group" => false, "archived" => false }] }
    )
    @sdk_api.expects(:get_all_categories).returns(response)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[categories list]) }
    assert_includes out, "Food"
  end

  def test_list_with_format
    response = stub(categories: [], to_hash: { "categories" => [] })
    @sdk_api.expects(:get_all_categories).returns(response)
    capture_stdout { LunchMoneyApp::Cli::Main.start(%w[categories list --format flattened]) }
  end

  def test_show_json
    category = stub(id: 1, to_hash: { "id" => 1, "name" => "Food" })
    @sdk_api.expects(:get_category_by_id).with(1).returns(category)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[categories show 1 --json]) }
    assert_equal "Food", JSON.parse(out)["name"]
  end

  def test_create
    @sdk_api.expects(:create_category).returns({ "id" => 2, "name" => "Transport" })
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[categories create --name Transport]) }
    assert_includes out, "Transport"
  end

  def test_create_json
    @sdk_api.expects(:create_category).returns({ "id" => 2, "name" => "Transport" })
    out = capture_stdout { LunchMoneyApp::Cli::Categories.start(%w[create --name Transport --json]) }
    parsed = JSON.parse(out)
    assert_equal 2, parsed["id"]
  end

  def test_update
    @sdk_api.expects(:update_category).with(5, { "name" => "Groceries" }).returns({ "id" => 5 })
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[categories update 5 --name Groceries]) }
    assert_includes out, "updated"
  end

  def test_delete
    @sdk_api.expects(:delete_category).with(7, {}).returns(nil)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[categories delete 7]) }
    assert_includes out, "deleted"
  end

  def test_delete_with_force
    @sdk_api.expects(:delete_category).with(7, { force: true }).returns(nil)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[categories delete 7 --force]) }
    assert_includes out, "deleted"
  end

  def test_delete_json
    @sdk_api.expects(:delete_category).with(7, {}).returns(nil)
    out = capture_stdout { LunchMoneyApp::Cli::Categories.start(%w[delete 7 --json]) }
    parsed = JSON.parse(out)
    assert_equal true, parsed["deleted"]
  end
end
