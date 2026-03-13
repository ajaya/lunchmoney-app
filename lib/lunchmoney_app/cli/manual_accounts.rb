# frozen_string_literal: true

require "thor"
require "terminal-table"

module LunchMoneyApp
  module Cli
    class ManualAccounts < Base
      class_option :json, type: :boolean, default: false, desc: "Output in JSON format"

      desc "list", "List all manually-managed accounts"
      def list
        ensure_setup!
        result = Api::ManualAccounts.list
        out.render(result) { |data| format_account_list(data.is_a?(Hash) ? data["manual_accounts"] || data.values.first : data) }
      end

      desc "show ID", "Show a single manual account"
      def show(id)
        ensure_setup!
        result = Api::ManualAccounts.get(id.to_i)
        out.render(result) { |data| JSON.pretty_generate(data) }
      end

      desc "create", "Create a new manual account"
      option :name, type: :string, required: true, desc: "Account name"
      option :type, type: :string, required: true, desc: "Account type",
             enum: ["cash", "credit", "cryptocurrency", "employee compensation", "investment", "loan", "other liability", "other asset", "real estate", "vehicle"]
      option :balance, type: :string, required: true, desc: "Current balance (up to 4 decimals)"
      option :institution_name, type: :string, desc: "Institution name"
      option :display_name, type: :string, desc: "Display name (must be unique per budget)"
      option :subtype, type: :string, desc: "Account subtype (e.g. retirement, checking, savings)"
      option :balance_as_of, type: :string, desc: "Date/time balance was last updated (ISO 8601)"
      option :currency, type: :string, desc: "Currency code (ISO 4217)"
      option :status, type: :string, enum: %w[active closed], desc: "Account status"
      option :closed_on, type: :string, desc: "Close date (YYYY-MM-DD), requires status=closed"
      option :external_id, type: :string, desc: "User-defined external ID"
      option :exclude_from_transactions, type: :boolean, desc: "Prevent transaction assignment"
      def create
        ensure_setup!
        fields = options.slice(
          "name", "type", "balance", "institution_name", "display_name",
          "subtype", "balance_as_of", "currency", "status", "closed_on",
          "external_id", "exclude_from_transactions"
        )
        result = Api::ManualAccounts.create(fields)
        result = LunchMoneyApp::Tool.serialize(result)
        out.render(result, "Created manual account: #{result["name"]} (id: #{result["id"]})")
      end

      desc "update ID", "Update a manual account"
      option :name, type: :string, desc: "Account name"
      option :balance, type: :string, desc: "Current balance (up to 4 decimals)"
      option :institution_name, type: :string, desc: "Institution name"
      option :display_name, type: :string, desc: "Display name (must be unique)"
      option :type, type: :string, desc: "Account type",
             enum: ["cash", "credit", "cryptocurrency", "employee compensation", "investment", "loan", "other liability", "other asset", "real estate", "vehicle"]
      option :subtype, type: :string, desc: "Account subtype"
      option :currency, type: :string, desc: "Currency code (ISO 4217)"
      option :balance_as_of, type: :string, desc: "Date/time balance was last updated (ISO 8601)"
      option :status, type: :string, enum: %w[active closed], desc: "Account status"
      option :closed_on, type: :string, desc: "Close date (YYYY-MM-DD)"
      option :external_id, type: :string, desc: "User-defined external ID"
      option :exclude_from_transactions, type: :boolean, desc: "Prevent transaction assignment"
      def update(id)
        ensure_setup!
        fields = options.slice(
          "name", "balance", "institution_name", "display_name", "type",
          "subtype", "currency", "balance_as_of", "status", "closed_on",
          "external_id", "exclude_from_transactions"
        )
        if fields.empty?
          abort "No fields to update. Use --name, --balance, --type, --currency, --status, etc."
        end
        result = Api::ManualAccounts.update(id.to_i, fields)
        out.render(result, "Manual account #{id} updated")
      end

      desc "delete ID", "Delete a manual account"
      option :delete_items, type: :boolean, desc: "Also delete transactions, rules, recurring items (irreversible)"
      option :delete_balance_history, type: :boolean, desc: "Also delete balance history"
      def delete(id)
        ensure_setup!
        Api::ManualAccounts.delete(
          id.to_i,
          delete_items: options[:delete_items] || false,
          delete_balance_history: options[:delete_balance_history] || false
        )
        out.render({ deleted: true, id: id.to_i }, "Manual account #{id} deleted")
      end

      private

      def out
        @out ||= Output.new(json: options[:json] || (parent_options && parent_options[:json]))
      end

      def format_account_list(accounts)
        return "No manual accounts found." if accounts.nil? || accounts.empty?

        rows = accounts.map do |acct|
          balance = format("%.2f", Float(acct["balance"] || 0))
          currency = acct["currency"]&.upcase || ""
          status = acct["status"] || ""
          institution = acct["institution_name"] || ""
          [acct["id"], acct["name"] || "Unknown", acct["type_name"] || acct["type"] || "", balance, currency, status, institution]
        end

        table = ::Terminal::Table.new(headings: %w[ID Name Type Balance Currency Status Institution], rows: rows)
        table.align_column(3, :right)
        table.to_s
      end
    end
  end
end
