# frozen_string_literal: true

module LunchMoneyApp
  module Tools
    class RecurringItems < LunchMoneyApp::Tool
      tool "get_all_recurring_items",
           description: "Get all recurring items (subscriptions, bills, etc.)",
           input_schema: {
             properties: {
               start_date:        { type: "string",  description: "Start date (YYYY-MM-DD)" },
               end_date:          { type: "string",  description: "End date (YYYY-MM-DD)" },
               include_suggested: { type: "boolean", description: "Include system-suggested items not yet reviewed" }
             }
           } do |args|
        text_response(Api::RecurringItems.list(args))
      end

      tool "get_recurring_item",
           description: "Get a single recurring item by ID",
           input_schema: {
             properties: {
               id:         { type: "integer", description: "Recurring item ID" },
               start_date: { type: "string",  description: "Start date for matching object (YYYY-MM-DD)" },
               end_date:   { type: "string",  description: "End date for matching object (YYYY-MM-DD)" }
             },
             required: ["id"]
           } do |args|
        id = args["id"]
        params = args.reject { |k, _| k == "id" }
        text_response(Api::RecurringItems.get(id, params))
      end
    end
  end
end
