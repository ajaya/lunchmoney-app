# frozen_string_literal: true

module LunchMoneyApp
  module Tools
    class User < LunchMoneyApp::Tool
      tool "get_me", description: "Get the current authenticated user's information" do |_args|
        text_response(Api::User.get_me)
      end
    end
  end
end
