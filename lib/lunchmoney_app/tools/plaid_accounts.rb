# frozen_string_literal: true

module LunchMoneyApp
  module Tools
    class PlaidAccounts < LunchMoneyApp::Tool
      tool "get_all_plaid_accounts", description: "Get all Plaid-connected accounts" do |_args|
        text_response(Api::PlaidAccounts.list)
      end

      tool "get_plaid_account",
           description: "Get a single Plaid account by ID",
           input_schema: {
             properties: { id: { type: "integer", description: "Plaid account ID" } },
             required:   ["id"]
           } do |args|
        text_response(Api::PlaidAccounts.get(args["id"]))
      end

      tool "trigger_plaid_fetch",
           description: "Trigger a Plaid data sync to fetch latest transactions",
           input_schema: {
             properties: {
               start_date: { type: "string",  description: "Start date for fetch (YYYY-MM-DD)" },
               end_date:   { type: "string",  description: "End date for fetch (YYYY-MM-DD)" },
               id:         { type: "integer", description: "Specific Plaid account ID to fetch" }
             }
           } do |args|
        Api::PlaidAccounts.fetch(start_date: args["start_date"], end_date: args["end_date"], id: args["id"])
        { content: [{ type: "text", text: "Plaid fetch triggered successfully." }] }
      end
    end
  end
end
