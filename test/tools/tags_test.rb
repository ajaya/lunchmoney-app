# frozen_string_literal: true

require "test_helper"

class TagsToolsTest < Minitest::Test
  def setup
    @client = mock("client")
    @server = LunchMoneyMcp::Server.new(@client)
    LunchMoneyMcp::Tools::Tags.register(@server)
  end

  def test_registers_all_tools
    %w[get_all_tags get_tag create_tag update_tag delete_tag].each do |name|
      assert @server.tool_registered?(name), "Expected #{name} to be registered"
    end
  end

  def test_get_all_tags
    tags = [{ "id" => 1, "name" => "vacation" }]
    @client.expects(:get).with("/tags").returns(tags)
    result = @server.call_tool("get_all_tags", {})
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal "vacation", parsed[0]["name"]
  end

  def test_get_tag
    tag = { "id" => 1, "name" => "vacation" }
    @client.expects(:get).with("/tags/1").returns(tag)
    result = @server.call_tool("get_tag", { "id" => 1 })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal "vacation", parsed["name"]
  end

  def test_create_tag
    @client.expects(:post).with("/tags", { "name" => "work" }).returns({ "id" => 2 })
    result = @server.call_tool("create_tag", { "name" => "work" })
    parsed = JSON.parse(result[:content][0][:text])
    assert_equal 2, parsed["id"]
  end

  def test_create_tag_with_colors
    body = { "name" => "urgent", "text_color" => "#fff", "background_color" => "#f00" }
    @client.expects(:post).with("/tags", body).returns({ "id" => 3 })
    @server.call_tool("create_tag", body)
  end

  def test_update_tag
    @client.expects(:put).with("/tags/1", { "name" => "holiday" }).returns({ "id" => 1 })
    @server.call_tool("update_tag", { "id" => 1, "name" => "holiday" })
  end

  def test_delete_tag
    @client.expects(:delete).with("/tags/1", {}).returns(nil)
    result = @server.call_tool("delete_tag", { "id" => 1 })
    assert_includes result[:content][0][:text], "deleted"
  end

  def test_delete_tag_with_force
    @client.expects(:delete).with("/tags/1", { force: true }).returns(nil)
    @server.call_tool("delete_tag", { "id" => 1, "force" => true })
  end
end
