# frozen_string_literal: true

require "test_helper"

class UserToolsTest < Minitest::Test
  def setup
    @server = build_server
    LunchMoneyApp::Tools::User.register(@server)

    @sdk_api = mock("me_api")
    LunchMoney::MeApi.stubs(:new).returns(@sdk_api)
  end

  def test_registers_get_me
    assert @server.tools.key?("get_me")
  end

  def test_get_me_returns_user_data
    user = stub(id: 1, to_hash: { "user_name" => "Ada", "user_email" => "ada@example.com" })
    @sdk_api.expects(:get_me).returns(user)

    result = call_tool(@server, "get_me")
    parsed = JSON.parse(result[:content][0][:text])

    assert_equal "Ada", parsed["user_name"]
    assert_equal "ada@example.com", parsed["user_email"]
  end

  def test_get_me_returns_text_content_type
    user = stub(id: 1, to_hash: {})
    @sdk_api.stubs(:get_me).returns(user)
    result = call_tool(@server, "get_me")
    assert_equal "text", result[:content][0][:type]
  end
end
