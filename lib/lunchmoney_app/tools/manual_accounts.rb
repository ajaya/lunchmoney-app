# frozen_string_literal: true

module LunchMoneyApp
  module Tools
    class ManualAccounts < LunchMoneyApp::Tool
      tool "get_all_manual_accounts", description: "Get all manually-managed accounts" do |_args|
        text_response(Api::ManualAccounts.list)
      end

      tool "get_manual_account",
           description: "Get a single manual account by ID",
           input_schema: {
             properties: { id: { type: "integer", description: "Manual account ID" } },
             required:   ["id"]
           } do |args|
        text_response(Api::ManualAccounts.get(args["id"]))
      end

      tool "create_manual_account",
           description: "Create a new manual account",
           input_schema: {
             properties: {
               name:                       { type: "string",  description: "Account name" },
               type:                       { type: "string",  description: "Account type", enum: ["cash", "credit", "cryptocurrency", "employee compensation", "investment", "loan", "other liability", "other asset", "real estate", "vehicle"] },
               balance:                    { type: "string",  description: "Current balance (up to 4 decimals)" },
               institution_name:           { type: "string",  description: "Institution name" },
               display_name:               { type: "string",  description: "Display name (must be unique per budget)" },
               subtype:                    { type: "string",  description: "Account subtype (e.g. retirement, checking, savings)" },
               balance_as_of:              { type: "string",  description: "Date/time balance was last updated (ISO 8601)" },
               currency:                   { type: "string",  description: "Currency code (ISO 4217)" },
               status:                     { type: "string",  description: "Account status", enum: %w[active closed] },
               closed_on:                  { type: "string",  description: "Close date (YYYY-MM-DD), requires status=closed" },
               external_id:                { type: "string",  description: "User-defined external ID" },
               custom_metadata:            { type: "object",  description: "Custom JSON metadata (max 4096 chars)" },
               exclude_from_transactions:  { type: "boolean", description: "Prevent transaction assignment" }
             },
             required: %w[name type balance]
           } do |args|
        text_response(Api::ManualAccounts.create(args))
      end

      tool "update_manual_account",
           description: "Update a manual account",
           input_schema: {
             properties: {
               id:                         { type: "integer", description: "Manual account ID" },
               name:                       { type: "string",  description: "Account name" },
               balance:                    { type: "string",  description: "Current balance (up to 4 decimals)" },
               institution_name:           { type: "string",  description: "Institution name" },
               display_name:               { type: "string",  description: "Display name (must be unique)" },
               type:                       { type: "string",  description: "Account type", enum: ["cash", "credit", "cryptocurrency", "employee compensation", "investment", "loan", "other liability", "other asset", "real estate", "vehicle"] },
               subtype:                    { type: "string",  description: "Account subtype" },
               currency:                   { type: "string",  description: "Currency code (ISO 4217)" },
               balance_as_of:              { type: "string",  description: "Date/time balance was last updated (ISO 8601)" },
               status:                     { type: "string",  description: "Account status", enum: %w[active closed] },
               closed_on:                  { type: "string",  description: "Close date (YYYY-MM-DD)" },
               external_id:                { type: "string",  description: "User-defined external ID" },
               custom_metadata:            { type: "object",  description: "Custom JSON metadata (max 4096 chars)" },
               exclude_from_transactions:  { type: "boolean", description: "Prevent transaction assignment" }
             },
             required: ["id"]
           } do |args|
        id = args["id"]
        fields = args.reject { |k, _| k == "id" }
        text_response(Api::ManualAccounts.update(id, fields))
      end

      tool "delete_manual_account",
           description: "Delete a manual account",
           input_schema: {
             properties: {
               id:                     { type: "integer", description: "Manual account ID to delete" },
               delete_items:           { type: "boolean", description: "Also delete transactions, rules, recurring items (irreversible)" },
               delete_balance_history: { type: "boolean", description: "Also delete balance history" }
             },
             required: ["id"]
           } do |args|
        Api::ManualAccounts.delete(args["id"], delete_items: args["delete_items"], delete_balance_history: args["delete_balance_history"])
        { content: [{ type: "text", text: "Manual account #{args["id"]} deleted successfully." }] }
      end
    end
  end
end
