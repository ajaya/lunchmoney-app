# frozen_string_literal: true

require "test_helper"

class TagsToolsTest < Minitest::Test
  def setup
    @server = build_server
    LunchMoneyApp::Tools::Tags.register(@server)

    @sdk_api = mock("tags_api")
    LunchMoney::TagsApi.stubs(:new).returns(@sdk_api)
  end

  def test_registers_all_tools
    %w[get_all_tags get_tag create_tag update_tag delete_tag].each do |name|
      assert @server.tools.key?(name), "Expected #{name} to be registered"
    end
  end

  def test_get_all_tags
    response = stub(tags: [stub(id: 1, to_hash: { "id" => 1, "name" => "vacation" })],
                    to_hash: [{ "id" => 1, "name" => "vacation" }])
    @sdk_api.expects(:get_all_tags).returns(response)
    result = call_tool(@server, "get_all_tags")
    assert result[:content][0][:text]
  end

  def test_get_tag
    tag = stub(id: 1, to_hash: { "id" => 1, "name" => "vacation" })
    @sdk_api.expects(:get_tag_by_id).with(1).returns(tag)
    result = call_tool(@server, "get_tag", { id: 1 })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal "vacation", parsed["name"]
  end

  def test_create_tag
    @sdk_api.expects(:create_tag).returns({ "id" => 2 })
    result = call_tool(@server, "create_tag", { name: "work" })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal 2, parsed["id"]
  end

  def test_create_tag_with_colors
    @sdk_api.expects(:create_tag).returns({ "id" => 3 })
    call_tool(@server, "create_tag", { name: "urgent", text_color: "#fff", background_color: "#f00" })
  end

  def test_update_tag
    @sdk_api.expects(:update_tag).with(1, { "name" => "holiday" }).returns({ "id" => 1 })
    call_tool(@server, "update_tag", { id: 1, name: "holiday" })
  end

  def test_delete_tag
    @sdk_api.expects(:delete_tag).returns(nil)
    result = call_tool(@server, "delete_tag", { id: 1 })
    assert_includes result[:content][0][:text], "deleted"
  end

  def test_delete_tag_with_force
    @sdk_api.expects(:delete_tag).returns(nil)
    call_tool(@server, "delete_tag", { id: 1, force: true })
  end
end
