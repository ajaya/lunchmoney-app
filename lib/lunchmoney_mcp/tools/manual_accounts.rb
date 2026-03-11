# frozen_string_literal: true

module LunchMoneyMcp
  module Tools
    class ManualAccounts < LunchMoneyMcp::Tool
      ACCOUNT_FIELDS = %w[
        name type balance institution_name display_name subtype currency
        balance_as_of status closed_on external_id exclude_from_transactions
      ].freeze

      tool "get_all_manual_accounts",
           description: "Get all manually-tracked accounts" do |_args, client|
        result = client.get("/assets")
        text_response(result)
      end

      tool "get_manual_account",
           description: "Get a single manual account by ID",
           input_schema: {
             properties: { id: { type: "integer", description: "Manual account ID" } },
             required:   ["id"]
           } do |args, client|
        result = client.get("/assets/#{args["id"]}")
        text_response(result)
      end

      tool "create_manual_account",
           description: "Create a new manually-tracked account",
           input_schema: {
             properties: {
               name:                       { type: "string",  description: "Account name" },
               type:                       { type: "string",  description: "Account type (e.g. 'checking', 'savings', 'credit', 'investment', 'property', 'vehicle', 'loan', 'other')" },
               balance:                    { type: "string",  description: "Current balance" },
               institution_name:           { type: "string",  description: "Financial institution name" },
               display_name:               { type: "string",  description: "Display name" },
               subtype:                    { type: "string",  description: "Account subtype" },
               currency:                   { type: "string",  description: "Currency code (e.g. 'usd')" },
               balance_as_of:              { type: "string",  description: "Date of balance (YYYY-MM-DD)" },
               status:                     { type: "string",  description: "Account status", enum: %w[active closed] },
               closed_on:                  { type: "string",  description: "Date account was closed" },
               external_id:                { type: "string",  description: "External ID" },
               exclude_from_transactions:  { type: "boolean", description: "Exclude from transaction views" }
             },
             required: %w[name type balance]
           } do |args, client|
        body   = args.slice(*ACCOUNT_FIELDS)
        result = client.post("/assets", body)
        text_response(result)
      end

      tool "update_manual_account",
           description: "Update an existing manual account",
           input_schema: {
             properties: {
               id:                         { type: "integer", description: "Manual account ID to update" },
               name:                       { type: "string",  description: "Account name" },
               type:                       { type: "string",  description: "Account type" },
               balance:                    { type: "string",  description: "Current balance" },
               institution_name:           { type: "string",  description: "Financial institution name" },
               display_name:               { type: "string",  description: "Display name" },
               subtype:                    { type: "string",  description: "Account subtype" },
               currency:                   { type: "string",  description: "Currency code" },
               balance_as_of:              { type: "string",  description: "Date of balance (YYYY-MM-DD)" },
               status:                     { type: "string",  description: "Account status", enum: %w[active closed] },
               closed_on:                  { type: "string",  description: "Date account was closed" },
               external_id:                { type: "string",  description: "External ID" },
               exclude_from_transactions:  { type: "boolean", description: "Exclude from transaction views" }
             },
             required: ["id"]
           } do |args, client|
        id     = args["id"]
        body   = args.slice(*ACCOUNT_FIELDS)
        result = client.put("/assets/#{id}", body)
        text_response(result)
      end

      tool "delete_manual_account",
           description: "Delete a manual account by ID",
           input_schema: {
             properties: { id: { type: "integer", description: "Manual account ID to delete" } },
             required:   ["id"]
           } do |args, client|
        id = args["id"]
        client.delete("/assets/#{id}")
        { content: [{ type: "text", text: "Manual account #{id} deleted successfully." }] }
      end
    end
  end
end
