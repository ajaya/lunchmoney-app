# frozen_string_literal: true

require "thor"
require "terminal-table"

module LunchMoneyApp
  module Cli
    class PlaidAccounts < Base
      class_option :json, type: :boolean, default: false, desc: "Output in JSON format"

      desc "list", "List all Plaid-connected accounts"
      def list
        ensure_setup!
        result = Api::PlaidAccounts.list
        out.render(result) { |data| format_account_list(data.is_a?(Hash) ? data["plaid_accounts"] || data.values.first : data) }
      end

      desc "show ID", "Show a single Plaid account"
      def show(id)
        ensure_setup!
        result = Api::PlaidAccounts.get(id.to_i)
        out.render(result) { |data| JSON.pretty_generate(data) }
      end

      desc "fetch", "Trigger a Plaid data sync"
      option :start_date, type: :string, desc: "Start date (YYYY-MM-DD)"
      option :end_date, type: :string, desc: "End date (YYYY-MM-DD)"
      option :id, type: :numeric, desc: "Specific Plaid account ID to fetch"
      def fetch
        ensure_setup!
        Api::PlaidAccounts.fetch(
          start_date: options[:start_date],
          end_date: options[:end_date],
          id: options[:id]
        )
        out.render({ triggered: true }, "Plaid fetch triggered successfully.")
      end

      private

      def out
        @out ||= Output.new(json: options[:json] || (parent_options && parent_options[:json]))
      end

      def format_account_list(accounts)
        return "No Plaid accounts found." if accounts.nil? || accounts.empty?

        rows = accounts.map do |acct|
          name = acct["display_name"] || acct["name"] || "Unknown"
          balance = acct["balance"] ? format("%.2f", Float(acct["balance"])) : ""
          currency = acct["currency"]&.upcase || ""
          institution = acct["institution_name"] || ""
          [acct["id"], name, acct["type"] || "", balance, currency, acct["status"] || "", institution]
        end

        table = ::Terminal::Table.new(headings: %w[ID Name Type Balance Currency Status Institution], rows: rows)
        table.align_column(3, :right)
        table.to_s
      end
    end
  end
end
