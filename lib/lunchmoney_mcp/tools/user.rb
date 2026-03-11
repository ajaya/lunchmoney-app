# frozen_string_literal: true

module LunchMoneyMcp
  module Tools
    class User < LunchMoneyMcp::Tool
      tool "get_me", description: "Get the current authenticated user's information" do |_args, client|
        result = client.get("/me")
        text_response(result)
      end
    end
  end
end
