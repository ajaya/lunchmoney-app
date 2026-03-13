# frozen_string_literal: true

module LunchMoneyApp
  module Tools
    class Summary < LunchMoneyApp::Tool
      tool "get_budget_summary",
           description: "Get budget summary for a date range",
           input_schema: {
             properties: {
               start_date:                   { type: "string",  description: "Start date (YYYY-MM-DD), should be first of month" },
               end_date:                     { type: "string",  description: "End date (YYYY-MM-DD), should be last of month" },
               include_totals:               { type: "boolean", description: "Include totals in the response" },
               include_rollover_pool:        { type: "boolean", description: "Include rollover pool amounts" },
               include_exclude_from_budgets: { type: "boolean", description: "Include categories excluded from budgets" },
               include_occurrences:          { type: "boolean", description: "Include per-budget-period occurrence details" },
               include_past_budget_dates:    { type: "boolean", description: "Include 3 budget periods prior to start_date (requires include_occurrences)" }
             },
             required: %w[start_date end_date]
           } do |args|
        params = args.reject { |k, _| %w[start_date end_date].include?(k) }
        text_response(Api::Summary.get_budget_summary(args["start_date"], args["end_date"], params))
      end
    end
  end
end
