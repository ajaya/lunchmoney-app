# frozen_string_literal: true

module LunchMoneyMcp
  module Tools
    class PlaidAccounts < LunchMoneyMcp::Tool
      tool "get_all_plaid_accounts", description: "Get all Plaid-connected accounts" do |_args, client|
        result = client.get("/plaid_accounts")
        text_response(result)
      end

      tool "get_plaid_account",
           description: "Get a single Plaid account by ID",
           input_schema: {
             properties: { id: { type: "integer", description: "Plaid account ID" } },
             required:   ["id"]
           } do |args, client|
        result = client.get("/plaid_accounts/#{args["id"]}")
        text_response(result)
      end

      tool "trigger_plaid_fetch",
           description: "Trigger a Plaid data sync to fetch latest transactions",
           input_schema: {
             properties: {
               start_date: { type: "string",  description: "Start date for fetch (YYYY-MM-DD)" },
               end_date:   { type: "string",  description: "End date for fetch (YYYY-MM-DD)" },
               id:         { type: "integer", description: "Specific Plaid account ID to fetch" }
             }
           } do |args, client|
        body = args.slice("start_date", "end_date", "id")
        client.post("/plaid_accounts/fetch", body)
        { content: [{ type: "text", text: "Plaid fetch triggered successfully." }] }
      end
    end
  end
end
