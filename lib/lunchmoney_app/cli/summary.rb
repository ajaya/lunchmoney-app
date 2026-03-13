# frozen_string_literal: true

require "thor"
require "terminal-table"

module LunchMoneyApp
  module Cli
    class Summary < Base
      class_option :json, type: :boolean, default: false, desc: "Output in JSON format"

      desc "budget", "Get budget summary for a date range"
      option :start_date, type: :string, required: true, desc: "Start date (YYYY-MM-DD), should be first of month"
      option :end_date, type: :string, required: true, desc: "End date (YYYY-MM-DD), should be last of month"
      option :include_totals, type: :boolean, desc: "Include totals in the response"
      option :include_rollover_pool, type: :boolean, desc: "Include rollover pool amounts"
      option :include_exclude_from_budgets, type: :boolean, desc: "Include categories excluded from budgets"
      option :include_occurrences, type: :boolean, desc: "Include per-budget-period occurrence details"
      option :include_past_budget_dates, type: :boolean, desc: "Include 3 budget periods prior to start_date (requires include_occurrences)"
      def budget
        ensure_setup!
        params = options.slice(
          "include_totals", "include_rollover_pool", "include_exclude_from_budgets",
          "include_occurrences", "include_past_budget_dates"
        )
        result = Api::Summary.get_budget_summary(options[:start_date], options[:end_date], params)
        out.render(result) { |data| format_budget_list(data) }
      end

      private

      def out
        @out ||= Output.new(json: options[:json] || (parent_options && parent_options[:json]))
      end

      def format_budget_list(budgets)
        return "No budget data found." if budgets.nil? || budgets.empty?

        rows = budgets.map do |entry|
          category = Api::Categories.cached(entry["category_id"], "name", fetch: true) || entry["category_name"] || "Uncategorized"
          budgeted = entry["budget_amount"] || entry["budgeted"] || "N/A"
          spending = entry["spending_to_base"] || entry["spending"] || "N/A"
          totals = entry["totals"]
          row = [category, budgeted, spending]
          if totals
            row += [
              totals["other_activity"] || "N/A",
              totals["recurring_activity"] || "N/A",
              totals["available"] || "N/A",
              totals["recurring_remaining"] || "N/A",
              totals["recurring_expected"] || "N/A"
            ]
          end
          row
        end

        has_totals = budgets.any? { |e| e["totals"] }
        headings = %w[Category Budgeted Spent]
        if has_totals
          headings += ["Other Activity", "Recurring Activity", "Available", "Recurring Remaining", "Recurring Expected"]
        end

        table = ::Terminal::Table.new(headings: headings, rows: rows)
        table.align_column(1, :right)
        table.align_column(2, :right)
        (3..7).each { |i| table.align_column(i, :right) } if has_totals
        table.to_s
      end
    end
  end
end
