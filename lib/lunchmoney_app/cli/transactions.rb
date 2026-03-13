# frozen_string_literal: true

require "thor"

module LunchMoneyApp
  module Cli
    class Transactions < Base
      class_option :json, type: :boolean, default: false, desc: "Output in JSON format"
      class_option :resolve, type: :boolean, default: false, desc: "Resolve foreign key IDs to full objects (requires --json)"

      desc "list", "List transactions"
      option :start_date, type: :string, desc: "Start date (YYYY-MM-DD)"
      option :end_date, type: :string, desc: "End date (YYYY-MM-DD)"
      option :created_since, type: :string, desc: "Filter by creation date (ISO 8601)"
      option :updated_since, type: :string, desc: "Filter by update date (ISO 8601)"
      option :category_id, type: :numeric, desc: "Filter by category ID"
      option :manual_account_id, type: :numeric, desc: "Filter by manual account ID"
      option :plaid_account_id, type: :numeric, desc: "Filter by Plaid account ID"
      option :tag_id, type: :numeric, desc: "Filter by tag ID"
      option :recurring_id, type: :numeric, desc: "Filter by recurring item ID"
      option :is_group_parent, type: :boolean, desc: "Filter to group parents only"
      option :status, type: :string, enum: %w[reviewed unreviewed delete_pending], desc: "Filter by status"
      option :is_pending, type: :boolean, desc: "Filter by pending status"
      option :include_pending, type: :boolean, desc: "Include pending transactions"
      option :include_split_parents, type: :boolean, desc: "Include split parent transactions"
      option :include_group_children, type: :boolean, desc: "Include group child transactions"
      option :include_children, type: :boolean, desc: "Include child transactions"
      option :include_files, type: :boolean, desc: "Include file attachments"
      option :include_metadata, type: :boolean, desc: "Include custom and plaid metadata"
      option :limit, type: :numeric, desc: "Max number of transactions"
      option :offset, type: :numeric, desc: "Offset for pagination"
      option :sort, type: :string, default: "desc", enum: %w[asc desc], desc: "Sort by date (default: desc, latest first)"
      def list
        ensure_setup!
        sort = options["sort"] || "desc"
        params = options.slice(
          "start_date", "end_date", "created_since", "updated_since",
          "category_id", "manual_account_id", "plaid_account_id",
          "tag_id", "recurring_id", "is_group_parent", "status",
          "is_pending", "include_pending", "include_split_parents",
          "include_group_children", "include_children", "include_files",
          "include_metadata", "limit", "offset"
        )
        result = Api::Transactions.list(params)
        out.render(result) { |data| format_transaction_list(data["transactions"], sort: sort) }
      end

      desc "show ID", "Show a single transaction"
      def show(id)
        ensure_setup!
        result = Api::Transactions.get(id.to_i)
        out.render(result) { |data| format_transaction_detail(data) }
      end

      desc "create", "Create transactions from JSON (reads stdin or --data)"
      option :data, type: :string, desc: "JSON array of transactions"
      option :apply_rules, type: :boolean, desc: "Apply category rules"
      option :skip_duplicates, type: :boolean, desc: "Skip duplicate transactions"
      option :skip_balance_update, type: :boolean, desc: "Skip balance update after insert"
      def create
        ensure_setup!
        transactions = parse_json_input(options[:data])
        result = Api::Transactions.create(
          transactions: transactions,
          apply_rules: options[:apply_rules],
          skip_duplicates: options[:skip_duplicates],
          skip_balance_update: options[:skip_balance_update]
        )
        out.render(result, "Created #{result["ids"]&.length || 0} transaction(s)")
      end

      desc "update ID", "Update a transaction"
      option :payee, type: :string, desc: "Payee name"
      option :amount, type: :string, desc: "Transaction amount"
      option :date, type: :string, desc: "Date (YYYY-MM-DD)"
      option :category_id, type: :numeric, desc: "Category ID"
      option :notes, type: :string, desc: "Notes"
      option :status, type: :string, enum: %w[reviewed unreviewed], desc: "Status"
      option :currency, type: :string, desc: "Currency code"
      option :manual_account_id, type: :numeric, desc: "Manual account ID"
      option :plaid_account_id, type: :numeric, desc: "Plaid account ID"
      option :recurring_id, type: :numeric, desc: "Recurring item ID"
      option :external_id, type: :string, desc: "External ID"
      def update(id)
        ensure_setup!
        fields = options.slice(
          "payee", "amount", "date", "category_id", "notes", "status", "currency",
          "manual_account_id", "plaid_account_id", "recurring_id", "external_id"
        )
        if fields.empty?
          abort "No fields to update. Use --payee, --amount, --date, --notes, --status, --category-id, --currency, etc."
        end
        result = Api::Transactions.update(id.to_i, fields)
        out.render(result, "Transaction #{id} updated")
      end

      desc "delete ID", "Delete a transaction"
      def delete(id)
        ensure_setup!
        Api::Transactions.delete(id.to_i)
        out.render({ deleted: true, id: id.to_i }, "Transaction #{id} deleted")
      end

      desc "delete_bulk ID1 ID2 ...", "Delete multiple transactions"
      def delete_bulk(*ids)
        ensure_setup!
        int_ids = ids.map(&:to_i)
        Api::Transactions.delete_bulk(int_ids)
        out.render({ deleted: true, ids: int_ids }, "#{int_ids.length} transaction(s) deleted")
      end

      desc "update_bulk", "Bulk update transactions (reads JSON array from --data or stdin, each must include id)"
      option :data, type: :string, desc: "JSON array of transactions with id fields"
      def update_bulk
        ensure_setup!
        transactions = parse_json_input(options[:data])
        result = Api::Transactions.update_bulk(transactions)
        out.render(result, "Bulk update complete")
      end

      desc "split ID", "Split a transaction (reads child_transactions JSON from --data or stdin)"
      option :data, type: :string, desc: "JSON array of child transactions"
      def split(id)
        ensure_setup!
        children = parse_json_input(options[:data])
        result = Api::Transactions.split(id.to_i, children)
        out.render(result, "Transaction #{id} split")
      end

      desc "unsplit ID", "Unsplit a transaction"
      def unsplit(id)
        ensure_setup!
        Api::Transactions.unsplit(id.to_i)
        out.render({ unsplit: true, id: id.to_i }, "Transaction #{id} unsplit")
      end

      desc "group", "Group transactions (reads JSON from --data or stdin with ids, date, payee)"
      option :data, type: :string, desc: 'JSON object with ids, date, payee, etc.'
      def group
        ensure_setup!
        data = parse_json_input(options[:data])
        data = data.is_a?(Hash) ? data : abort("Expected a JSON object with ids, date, payee")
        result = Api::Transactions.group(
          ids: data["ids"], date: data["date"], payee: data["payee"],
          category_id: data["category_id"], notes: data["notes"],
          status: data["status"], tag_ids: data["tag_ids"]
        )
        out.render(result, "Transactions grouped")
      end

      desc "ungroup ID", "Ungroup a transaction group"
      def ungroup(id)
        ensure_setup!
        Api::Transactions.ungroup(id.to_i)
        out.render({ ungrouped: true, id: id.to_i }, "Transaction group #{id} ungrouped")
      end

      private

      def out
        @out ||= Output.new(
          json: options[:json] || (parent_options && parent_options[:json]),
          resolve: options[:resolve] || (parent_options && parent_options[:resolve])
        )
      end

      def format_transaction_list(transactions, sort: nil)
        return "No transactions found." if transactions.nil? || transactions.empty?

        if sort == "desc"
          transactions = transactions.sort_by { |t| [t["date"] || "", t["id"] || 0] }.reverse
        elsif sort == "asc"
          transactions = transactions.sort_by { |t| [t["date"] || "", t["id"] || 0] }
        end

        max_payee = 40
        rows = transactions.map do |txn|
          payee = txn["payee"]&.strip || "Unknown"
          payee = "#{payee[0, max_payee - 1]}…" if payee.length > max_payee
          amount = format("%.2f", Float(txn["amount"] || 0))
          currency = txn["currency"]&.upcase || ""
          category = Api::Categories.cached(txn["category_id"], "name") || ""
          [txn["id"], txn["date"] || "N/A", amount, currency, txn["status"] || "", category, payee]
        end

        table = ::Terminal::Table.new(headings: %w[ID Date Amount Currency Status Category Payee], rows: rows)
        table.align_column(2, :right)
        table.to_s
      end

      def format_transaction_detail(txn)
        rows = []
        rows << ["ID", txn["id"]]
        rows << ["Date", txn["date"]] if txn["date"]
        rows << ["Payee", txn["payee"]] if txn["payee"]
        rows << ["Amount", "#{txn["amount"]} #{txn["currency"]&.upcase}".rstrip] if txn["amount"]
        rows << ["Status", txn["status"]] if txn["status"]
        rows << ["Notes", txn["notes"]] if txn["notes"] && !txn["notes"].empty?
        if txn["category_id"] || txn["category"]
          cat_name = txn.dig("category", "name") || Api::Categories.cached(txn["category_id"], "name") || txn["category_id"]
          rows << ["Category", cat_name]
        end
        if txn["plaid_account_id"] || txn["plaid_account"]
          acct_name = txn.dig("plaid_account", "name") || Api::PlaidAccounts.cached(txn["plaid_account_id"], "display_name") || Api::PlaidAccounts.cached(txn["plaid_account_id"], "name") || txn["plaid_account_id"]
          rows << ["Account", acct_name]
        end
        if txn["manual_account_id"] || txn["manual_account"]
          acct_name = txn.dig("manual_account", "name") || Api::ManualAccounts.cached(txn["manual_account_id"], "name") || txn["manual_account_id"]
          rows << ["Account", acct_name]
        end
        if txn["tag_ids"]&.any?
          tag_names = txn["tag_ids"].filter_map { |id| Api::Tags.cached(id, "name") }
          rows << ["Tags", tag_names.join(", ")] unless tag_names.empty?
        elsif txn["tags"]&.any?
          rows << ["Tags", txn["tags"].map { |t| t.is_a?(Hash) ? t["name"] : t }.join(", ")]
        end
        rows << ["Recurring", txn["recurring_id"]] if txn["recurring_id"]
        rows << ["Group", txn["group_id"]] if txn["group_id"]
        rows << ["External", txn["external_id"]] if txn["external_id"] && !txn["external_id"].empty?

        ::Terminal::Table.new(title: "Transaction ##{txn["id"]}", rows: rows).to_s
      end

      def parse_json_input(data_option)
        raw = data_option || ($stdin.tty? ? abort("Provide --data or pipe JSON via stdin") : $stdin.read)
        JSON.parse(raw)
      rescue JSON::ParserError => e
        abort "Invalid JSON: #{e.message}"
      end
    end
  end
end
