# frozen_string_literal: true

require "test_helper"

class UserToolsTest < Minitest::Test
  def setup
    @client = mock("client")
    @server = LunchMoneyMcp::Server.new(@client)
    LunchMoneyMcp::Tools::User.register(@server)
  end

  def test_registers_get_me
    assert @server.tool_registered?("get_me")
  end

  def test_get_me_returns_user_data
    user = { "user_name" => "Ada", "user_email" => "ada@example.com" }
    @client.expects(:get).with("/me").returns(user)

    result = @server.call_tool("get_me", {})
    parsed = JSON.parse(result[:content][0][:text])

    assert_equal "Ada", parsed["user_name"]
    assert_equal "ada@example.com", parsed["user_email"]
  end

  def test_get_me_returns_text_content_type
    @client.stubs(:get).returns({})
    result = @server.call_tool("get_me", {})
    assert_equal "text", result[:content][0][:type]
  end
end
