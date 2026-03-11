# frozen_string_literal: true

module LunchMoneyMcp
  module Tools
    class RecurringItems < LunchMoneyMcp::Tool
      tool "get_all_recurring_items",
           description: "Get all recurring items (expenses and income)",
           input_schema: {
             properties: {
               start_date:        { type: "string",  description: "Start date (YYYY-MM-DD)" },
               end_date:          { type: "string",  description: "End date (YYYY-MM-DD)" },
               include_suggested: { type: "boolean", description: "Include suggested recurring items" }
             }
           } do |args, client|
        params = args.slice("start_date", "end_date", "include_suggested")
        result = client.get("/recurring_expenses", params)
        text_response(result)
      end

      tool "get_recurring_item",
           description: "Get a single recurring item by ID",
           input_schema: {
             properties: { id: { type: "integer", description: "Recurring item ID" } },
             required:   ["id"]
           } do |args, client|
        result = client.get("/recurring_expenses/#{args["id"]}")
        text_response(result)
      end
    end
  end
end
