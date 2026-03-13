# frozen_string_literal: true

require "thor"
require "terminal-table"

module LunchMoneyApp
  module Cli
    class RecurringItems < Base
      class_option :json, type: :boolean, default: false, desc: "Output in JSON format"

      desc "list", "List all recurring items (subscriptions, bills, etc.)"
      option :start_date, type: :string, desc: "Start date (YYYY-MM-DD)"
      option :end_date, type: :string, desc: "End date (YYYY-MM-DD)"
      option :include_suggested, type: :boolean, desc: "Include system-suggested items not yet reviewed"
      def list
        ensure_setup!
        params = options.slice("start_date", "end_date", "include_suggested")
        result = Api::RecurringItems.list(params)
        out.render(result) { |data| format_recurring_list(data["recurring_items"] || data["recurring_expenses"] || data) }
      end

      desc "show ID", "Show a single recurring item"
      option :start_date, type: :string, desc: "Start date for matching object (YYYY-MM-DD)"
      option :end_date, type: :string, desc: "End date for matching object (YYYY-MM-DD)"
      def show(id)
        ensure_setup!
        params = options.slice("start_date", "end_date")
        result = Api::RecurringItems.get(id.to_i, params)
        out.render(result) { |data| JSON.pretty_generate(data) }
      end

      private

      def out
        @out ||= Output.new(json: options[:json] || (parent_options && parent_options[:json]))
      end

      def format_recurring_list(items)
        return "No recurring items found." if items.nil? || items.empty?

        rows = items.map do |item|
          criteria = item["transaction_criteria"] || {}
          overrides = item["overrides"] || {}
          payee = overrides["payee"] || criteria["payee"] || item["payee"] || "Unknown"
          raw_amount = criteria["amount"] || item["amount"] || 0
          amount = format("%.2f", Float(raw_amount))
          cadence = [criteria["granularity"], criteria["quantity"]].compact.join(" x ") if criteria["granularity"]
          cadence ||= item["cadence"] || ""
          [item["id"], payee, amount, criteria["currency"]&.upcase || "", cadence]
        end

        table = ::Terminal::Table.new(headings: %w[ID Payee Amount Currency Cadence], rows: rows)
        table.align_column(2, :right)
        table.to_s
      end
    end
  end
end
