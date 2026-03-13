# frozen_string_literal: true

require "test_helper"

class CliTagsTest < Minitest::Test
  def setup
    LunchMoneyApp::Cache.new(":memory:")
    LunchMoneyApp::Cli::Main.stubs(:setup_from_config!)

    @sdk_api = mock("tags_api")
    LunchMoney::TagsApi.stubs(:new).returns(@sdk_api)
  end

  def test_list_json
    response = stub(
      tags: [stub(id: 1, to_hash: { "id" => 1, "name" => "vacation" })],
      to_hash: [{ "id" => 1, "name" => "vacation" }]
    )
    @sdk_api.expects(:get_all_tags).returns(response)
    out = capture_stdout { LunchMoneyApp::Cli::Tags.start(%w[list --json]) }
    parsed = JSON.parse(out)
    assert_equal "vacation", parsed[0]["name"]
  end

  def test_list_human
    response = stub(
      tags: [stub(id: 1, to_hash: { "id" => 1, "name" => "vacation" })],
      to_hash: [{ "id" => 1, "name" => "vacation" }]
    )
    @sdk_api.expects(:get_all_tags).returns(response)
    out = capture_stdout { LunchMoneyApp::Cli::Tags.start(%w[list]) }
    assert_includes out, "vacation"
  end

  def test_show_json
    tag = stub(id: 1, to_hash: { "id" => 1, "name" => "vacation" })
    @sdk_api.expects(:get_tag_by_id).with(1).returns(tag)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[tags show 1 --json]) }
    assert_equal "vacation", JSON.parse(out)["name"]
  end

  def test_create
    @sdk_api.expects(:create_tag).returns({ "id" => 2, "name" => "work" })
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[tags create --name work]) }
    assert_includes out, "work"
  end

  def test_create_json
    @sdk_api.expects(:create_tag).returns({ "id" => 2, "name" => "work" })
    out = capture_stdout { LunchMoneyApp::Cli::Tags.start(%w[create --name work --json]) }
    parsed = JSON.parse(out)
    assert_equal 2, parsed["id"]
  end

  def test_update
    @sdk_api.expects(:update_tag).with(5, { "name" => "holiday" }).returns({ "id" => 5 })
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[tags update 5 --name holiday]) }
    assert_includes out, "updated"
  end

  def test_delete
    @sdk_api.expects(:delete_tag).with(7, {}).returns(nil)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[tags delete 7]) }
    assert_includes out, "deleted"
  end

  def test_delete_with_force
    @sdk_api.expects(:delete_tag).with(7, { force: true }).returns(nil)
    out = capture_stdout { LunchMoneyApp::Cli::Main.start(%w[tags delete 7 --force]) }
    assert_includes out, "deleted"
  end

  def test_delete_json
    @sdk_api.expects(:delete_tag).with(7, {}).returns(nil)
    out = capture_stdout { LunchMoneyApp::Cli::Tags.start(%w[delete 7 --json]) }
    parsed = JSON.parse(out)
    assert_equal true, parsed["deleted"]
  end
end
