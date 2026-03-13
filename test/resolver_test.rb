# frozen_string_literal: true

require "test_helper"

class ResolverTest < Minitest::Test
  def setup
    LunchMoneyApp::Cache.new(":memory:")
    @categories_api = mock("categories_api")
    @plaid_api = mock("plaid_api")
    @manual_api = mock("manual_api")
    @tags_api = mock("tags_api")
    LunchMoney::CategoriesApi.stubs(:new).returns(@categories_api)
    LunchMoney::PlaidAccountsApi.stubs(:new).returns(@plaid_api)
    LunchMoney::ManualAccountsApi.stubs(:new).returns(@manual_api)
    LunchMoney::TagsApi.stubs(:new).returns(@tags_api)
  end

  def test_resolves_category_from_cache
    LunchMoneyApp::Api::Categories.sync_record(5, { "id" => 5, "name" => "Groceries" })

    txn = { "id" => 1, "payee" => "Store", "category_id" => 5 }
    result = LunchMoneyApp::Resolver.resolve(txn)

    assert_equal({ "id" => 5, "name" => "Groceries" }, result["category"])
    assert_equal 5, result["category_id"]
  end

  def test_resolves_category_via_api_fallback
    category = stub(id: 5, to_hash: { "id" => 5, "name" => "Dining" })
    @categories_api.expects(:get_category_by_id).with(5).returns(category)

    txn = { "id" => 1, "payee" => "Restaurant", "category_id" => 5 }
    result = LunchMoneyApp::Resolver.resolve(txn)

    assert_equal "Dining", result["category"]["name"]
    # Verify it was cached for next time
    assert_equal "Dining", LunchMoneyApp::Api::Categories.cached(5)["name"]
  end

  def test_graceful_failure_on_api_error
    @categories_api.expects(:get_category_by_id).with(999).raises(StandardError, "Not found")

    txn = { "id" => 1, "payee" => "Unknown", "category_id" => 999 }
    result = LunchMoneyApp::Resolver.resolve(txn)

    assert_nil result["category"]
    assert_equal 999, result["category_id"]
  end

  def test_resolves_nested_envelope
    LunchMoneyApp::Api::Categories.sync_record(5, { "id" => 5, "name" => "Groceries" })

    data = { "transactions" => [{ "id" => 1, "category_id" => 5 }] }
    result = LunchMoneyApp::Resolver.resolve(data)

    assert_equal "Groceries", result["transactions"][0]["category"]["name"]
  end

  def test_nil_category_id_passthrough
    txn = { "id" => 1, "payee" => "Store", "category_id" => nil }
    result = LunchMoneyApp::Resolver.resolve(txn)

    assert_nil result["category"]
  end

  def test_missing_category_id_passthrough
    txn = { "id" => 1, "payee" => "Store" }
    result = LunchMoneyApp::Resolver.resolve(txn)

    refute result.key?("category")
  end

  def test_batch_prefetch_calls_list_once
    response = stub(categories: [
      stub(id: 5, to_hash: { "id" => 5, "name" => "Groceries" }),
      stub(id: 6, to_hash: { "id" => 6, "name" => "Dining" })
    ], to_hash: { "categories" => [] })
    @categories_api.expects(:get_all_categories).returns(response).once

    txns = [
      { "id" => 1, "category_id" => 5 },
      { "id" => 2, "category_id" => 6 },
      { "id" => 3, "category_id" => 5 }
    ]
    result = LunchMoneyApp::Resolver.resolve(txns)

    assert_equal "Groceries", result[0]["category"]["name"]
    assert_equal "Dining", result[1]["category"]["name"]
    assert_equal "Groceries", result[2]["category"]["name"]
  end

  def test_resolves_group_id_inside_category
    LunchMoneyApp::Api::Categories.sync_record(10, { "id" => 10, "name" => "Food", "is_group" => true })
    LunchMoneyApp::Api::Categories.sync_record(5, { "id" => 5, "name" => "Groceries", "group_id" => 10 })

    txn = { "id" => 1, "category_id" => 5 }
    result = LunchMoneyApp::Resolver.resolve(txn)

    assert_equal "Groceries", result["category"]["name"]
    assert_equal({ "id" => 10, "name" => "Food", "is_group" => true }, result["category"]["group"])
  end

  def test_nil_group_id_no_group_embedded
    LunchMoneyApp::Api::Categories.sync_record(5, { "id" => 5, "name" => "Groceries", "group_id" => nil })

    txn = { "id" => 1, "category_id" => 5 }
    result = LunchMoneyApp::Resolver.resolve(txn)

    assert_equal "Groceries", result["category"]["name"]
    refute result["category"].key?("group")
  end

  def test_resolves_plaid_account_id
    LunchMoneyApp::Api::PlaidAccounts.sync_record(100, { "id" => 100, "name" => "Chase Checking" })

    txn = { "id" => 1, "plaid_account_id" => 100 }
    result = LunchMoneyApp::Resolver.resolve(txn)

    assert_equal({ "id" => 100, "name" => "Chase Checking" }, result["plaid_account"])
  end

  def test_resolves_manual_account_id
    LunchMoneyApp::Api::ManualAccounts.sync_record(200, { "id" => 200, "name" => "Cash" })

    txn = { "id" => 1, "manual_account_id" => 200 }
    result = LunchMoneyApp::Resolver.resolve(txn)

    assert_equal({ "id" => 200, "name" => "Cash" }, result["manual_account"])
  end

  def test_resolves_tag_ids
    LunchMoneyApp::Api::Tags.sync_record(1, { "id" => 1, "name" => "food" })
    LunchMoneyApp::Api::Tags.sync_record(2, { "id" => 2, "name" => "travel" })

    txn = { "id" => 1, "tag_ids" => [1, 2] }
    result = LunchMoneyApp::Resolver.resolve(txn)

    assert_equal [{ "id" => 1, "name" => "food" }, { "id" => 2, "name" => "travel" }], result["tags"]
  end

  def test_empty_tag_ids_no_tags_embedded
    txn = { "id" => 1, "tag_ids" => [] }
    result = LunchMoneyApp::Resolver.resolve(txn)

    refute result.key?("tags")
  end

  def test_null_account_ids_passthrough
    txn = { "id" => 1, "plaid_account_id" => nil, "manual_account_id" => nil }
    result = LunchMoneyApp::Resolver.resolve(txn)

    refute result.key?("plaid_account")
    refute result.key?("manual_account")
  end

  def test_resolves_all_fields_together
    LunchMoneyApp::Api::Categories.sync_record(5, { "id" => 5, "name" => "Groceries" })
    LunchMoneyApp::Api::PlaidAccounts.sync_record(100, { "id" => 100, "name" => "Chase" })
    LunchMoneyApp::Api::Tags.sync_record(1, { "id" => 1, "name" => "food" })

    txn = { "id" => 1, "category_id" => 5, "plaid_account_id" => 100, "manual_account_id" => nil, "tag_ids" => [1] }
    result = LunchMoneyApp::Resolver.resolve(txn)

    assert_equal "Groceries", result["category"]["name"]
    assert_equal "Chase", result["plaid_account"]["name"]
    refute result.key?("manual_account")
    assert_equal [{ "id" => 1, "name" => "food" }], result["tags"]
  end

  def test_does_not_modify_original
    LunchMoneyApp::Api::Categories.sync_record(5, { "id" => 5, "name" => "Groceries" })

    txn = { "id" => 1, "category_id" => 5 }
    result = LunchMoneyApp::Resolver.resolve(txn)

    refute txn.key?("category")
    assert result.key?("category")
  end
end
