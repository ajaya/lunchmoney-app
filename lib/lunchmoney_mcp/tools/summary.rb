# frozen_string_literal: true

module LunchMoneyMcp
  module Tools
    class Summary < LunchMoneyMcp::Tool
      tool "get_budget_summary",
           description: "Get budget summary for a date range with category breakdowns, totals, and optional rollover data",
           input_schema: {
             properties: {
               start_date:                    { type: "string",  description: "Start date (YYYY-MM-DD)" },
               end_date:                      { type: "string",  description: "End date (YYYY-MM-DD)" },
               include_exclude_from_budgets:  { type: "boolean", description: "Include categories excluded from budgets" },
               include_occurrences:           { type: "boolean", description: "Include recurring occurrences" },
               include_past_budget_dates:     { type: "boolean", description: "Include past budget dates" },
               include_totals:                { type: "boolean", description: "Include totals" },
               include_rollover_pool:         { type: "boolean", description: "Include rollover pool data" }
             },
             required: %w[start_date end_date]
           } do |args, client|
        params = args.slice(
          "start_date", "end_date", "include_exclude_from_budgets",
          "include_occurrences", "include_past_budget_dates",
          "include_totals", "include_rollover_pool"
        )
        result = client.get("/budgets", params)
        text_response(result)
      end
    end
  end
end
