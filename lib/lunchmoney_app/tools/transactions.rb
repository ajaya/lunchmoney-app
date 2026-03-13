# frozen_string_literal: true

module LunchMoneyApp
  module Tools
    class Transactions < LunchMoneyApp::Tool
      tool "get_all_transactions",
           description: "Get all transactions with optional filters for date range, account, category, tags, status, and pagination",
           input_schema: {
             properties: {
               start_date:             { type: "string",  description: "Start date (YYYY-MM-DD)" },
               end_date:               { type: "string",  description: "End date (YYYY-MM-DD)" },
               created_since:          { type: "string",  description: "Filter by creation date (ISO 8601)" },
               updated_since:          { type: "string",  description: "Filter by update date (ISO 8601)" },
               manual_account_id:      { type: "integer", description: "Filter by manual account ID" },
               plaid_account_id:       { type: "integer", description: "Filter by Plaid account ID" },
               recurring_id:           { type: "integer", description: "Filter by recurring item ID" },
               category_id:            { type: "integer", description: "Filter by category ID" },
               tag_id:                 { type: "integer", description: "Filter by tag ID" },
               is_group_parent:        { type: "boolean", description: "Filter to group parents only" },
               status:                 { type: "string",  description: "Filter by status", enum: %w[reviewed unreviewed delete_pending] },
               is_pending:             { type: "boolean", description: "Filter by pending status" },
               include_pending:        { type: "boolean", description: "Include pending transactions" },
               include_split_parents:  { type: "boolean", description: "Include split parent transactions" },
               include_group_children: { type: "boolean", description: "Include group child transactions" },
               include_children:       { type: "boolean", description: "Include child transactions" },
               include_files:          { type: "boolean", description: "Include file attachments" },
               include_metadata:       { type: "boolean", description: "Include custom and plaid metadata" },
               limit:                  { type: "integer", description: "Max number of transactions to return" },
               offset:                 { type: "integer", description: "Offset for pagination" }
             }
           } do |args|
        text_response(Api::Transactions.list(args))
      end

      tool "get_transaction",
           description: "Get a single transaction by ID",
           input_schema: {
             properties: { id: { type: "integer", description: "Transaction ID" } },
             required:   ["id"]
           } do |args|
        text_response(Api::Transactions.get(args["id"]))
      end

      tool "create_transactions",
           description: "Create one or more transactions",
           input_schema: {
             properties: {
               transactions:        { type: "array",   description: "Array of transactions to create", items: { type: "object" } },
               apply_rules:         { type: "boolean", description: "Apply category rules to new transactions" },
               skip_duplicates:     { type: "boolean", description: "Skip duplicate transactions" },
               skip_balance_update: { type: "boolean", description: "Skip balance update after insert" }
             },
             required: ["transactions"]
           } do |args|
        text_response(Api::Transactions.create(
          transactions: args["transactions"],
          apply_rules: args["apply_rules"],
          skip_duplicates: args["skip_duplicates"],
          skip_balance_update: args["skip_balance_update"]
        ))
      end

      tool "update_transaction",
           description: "Update a single transaction",
           input_schema: {
             properties: {
               id:          { type: "integer", description: "Transaction ID to update" },
               date:        { type: "string",  description: "Transaction date (YYYY-MM-DD)" },
               payee:       { type: "string",  description: "Payee name" },
               amount:      { type: "string",  description: "Transaction amount" },
               currency:    { type: "string",  description: "Currency code" },
               notes:       { type: "string",  description: "Transaction notes" },
               category_id: { type: "integer", description: "Category ID" },
               status:      { type: "string",  description: "Transaction status", enum: %w[reviewed unreviewed] },
               manual_account_id:  { type: "integer", description: "Manual account ID" },
               plaid_account_id:   { type: "integer", description: "Plaid account ID" },
               tag_ids:            { type: "array",   description: "Array of tag IDs (replaces all)", items: { type: "integer" } },
               additional_tag_ids: { type: "array",   description: "Array of tag IDs to add (mutually exclusive with tag_ids)", items: { type: "integer" } },
               recurring_id:       { type: "integer", description: "Recurring item ID" },
               external_id:        { type: "string",  description: "External ID" },
               custom_metadata:    { type: "object",  description: "Custom JSON metadata" }
             },
             required: ["id"]
           } do |args|
        id = args["id"]
        fields = args.reject { |k, _| k == "id" }
        text_response(Api::Transactions.update(id, fields))
      end

      tool "delete_transaction",
           description: "Delete a single transaction by ID",
           input_schema: {
             properties: { id: { type: "integer", description: "Transaction ID to delete" } },
             required:   ["id"]
           } do |args|
        Api::Transactions.delete(args["id"])
        { content: [{ type: "text", text: "Transaction #{args["id"]} deleted successfully." }] }
      end

      tool "delete_transactions",
           description: "Bulk delete multiple transactions by IDs",
           input_schema: {
             properties: {
               ids: { type: "array", description: "Array of transaction IDs to delete", items: { type: "integer" } }
             },
             required: ["ids"]
           } do |args|
        ids = args["ids"]
        Api::Transactions.delete_bulk(ids)
        { content: [{ type: "text", text: "#{ids.length} transaction(s) deleted successfully." }] }
      end

      tool "update_transactions",
           description: "Bulk update multiple transactions",
           input_schema: {
             properties: {
               transactions: {
                 type:        "array",
                 description: "Array of transactions to update, each must include an id",
                 items:       { type: "object" }
               }
             },
             required: ["transactions"]
           } do |args|
        text_response(Api::Transactions.update_bulk(args["transactions"]))
      end

      tool "split_transaction",
           description: "Split a transaction into multiple child transactions",
           input_schema: {
             properties: {
               id:                 { type: "integer", description: "Transaction ID to split" },
               child_transactions: {
                 type:        "array",
                 description: "Array of split child transactions",
                 items:       { type: "object" }
               }
             },
             required: %w[id child_transactions]
           } do |args|
        text_response(Api::Transactions.split(args["id"], args["child_transactions"]))
      end

      tool "unsplit_transaction",
           description: "Unsplit a previously split transaction",
           input_schema: {
             properties: { id: { type: "integer", description: "Transaction ID to unsplit" } },
             required:   ["id"]
           } do |args|
        Api::Transactions.unsplit(args["id"])
        { content: [{ type: "text", text: "Transaction #{args["id"]} unsplit successfully." }] }
      end

      tool "group_transactions",
           description: "Group multiple transactions together",
           input_schema: {
             properties: {
               ids:         { type: "array",   description: "Array of transaction IDs to group", items: { type: "integer" } },
               date:        { type: "string",  description: "Group date (YYYY-MM-DD)" },
               payee:       { type: "string",  description: "Group payee name" },
               category_id: { type: "integer", description: "Category ID for the group" },
               notes:       { type: "string",  description: "Notes for the group" },
               status:      { type: "string",  description: "Group status", enum: %w[reviewed unreviewed] },
               tag_ids:     { type: "array",   description: "Array of tag IDs", items: { type: "integer" } }
             },
             required: %w[ids date payee]
           } do |args|
        text_response(Api::Transactions.group(
          ids: args["ids"], date: args["date"], payee: args["payee"],
          category_id: args["category_id"], notes: args["notes"],
          status: args["status"], tag_ids: args["tag_ids"]
        ))
      end

      tool "ungroup_transaction",
           description: "Ungroup a previously grouped transaction",
           input_schema: {
             properties: { id: { type: "integer", description: "Group transaction ID to ungroup" } },
             required:   ["id"]
           } do |args|
        Api::Transactions.ungroup(args["id"])
        { content: [{ type: "text", text: "Transaction group #{args["id"]} ungrouped successfully." }] }
      end

      tool "attach_file",
           description: "Attach a file to a transaction",
           input_schema: {
             properties: {
               transaction_id: { type: "integer", description: "Transaction ID to attach file to" },
               file:           { type: "string",  description: "File content (base64 encoded)" },
               notes:          { type: "string",  description: "Notes about the attachment" }
             },
             required: %w[transaction_id file]
           } do |args|
        text_response(Api::Transactions.attach_file(args["transaction_id"], file: args["file"], notes: args["notes"]))
      end

      tool "get_attachment_url",
           description: "Get the URL for a transaction file attachment",
           input_schema: {
             properties: { file_id: { type: "integer", description: "File attachment ID" } },
             required:   ["file_id"]
           } do |args|
        text_response(Api::Transactions.get_attachment_url(args["file_id"]))
      end

      tool "delete_attachment",
           description: "Delete a file attachment from a transaction",
           input_schema: {
             properties: { file_id: { type: "integer", description: "File attachment ID to delete" } },
             required:   ["file_id"]
           } do |args|
        Api::Transactions.delete_attachment(args["file_id"])
        { content: [{ type: "text", text: "Attachment #{args["file_id"]} deleted successfully." }] }
      end
    end
  end
end
