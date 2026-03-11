# frozen_string_literal: true

module LunchMoneyMcp
  module Tools
    class Categories < LunchMoneyMcp::Tool
      tool "get_all_categories",
           description: "Get all categories, optionally nested or flattened",
           input_schema: {
             properties: {
               format:   { type: "string", description: "Response format", enum: %w[nested flattened] },
               is_group: { type: "boolean", description: "Filter to only category groups" }
             }
           } do |args, client|
        params = args.slice("format", "is_group")
        result = client.get("/categories", params)
        text_response(result)
      end

      tool "get_category",
           description: "Get a single category by ID",
           input_schema: {
             properties: { id: { type: "integer", description: "Category ID" } },
             required:   ["id"]
           } do |args, client|
        result = client.get("/categories/#{args["id"]}")
        text_response(result)
      end

      tool "create_category",
           description: "Create a new category",
           input_schema: {
             properties: {
               name:                  { type: "string",  description: "Category name" },
               description:           { type: "string",  description: "Category description" },
               is_income:             { type: "boolean", description: "Whether this is an income category" },
               exclude_from_budget:   { type: "boolean", description: "Exclude from budget" },
               exclude_from_totals:   { type: "boolean", description: "Exclude from totals" },
               is_group:              { type: "boolean", description: "Whether this is a category group" },
               group_id:              { type: "integer", description: "Parent group ID" },
               archived:              { type: "boolean", description: "Whether the category is archived" },
               order:                 { type: "integer", description: "Display order" }
             },
             required: ["name"]
           } do |args, client|
        body = args.slice("name", "description", "is_income", "exclude_from_budget",
                          "exclude_from_totals", "is_group", "group_id", "archived", "order")
        result = client.post("/categories", body)
        text_response(result)
      end

      tool "update_category",
           description: "Update an existing category",
           input_schema: {
             properties: {
               id:                  { type: "integer", description: "Category ID to update" },
               name:                { type: "string",  description: "Category name" },
               description:         { type: "string",  description: "Category description" },
               is_income:           { type: "boolean", description: "Whether this is an income category" },
               exclude_from_budget: { type: "boolean", description: "Exclude from budget" },
               exclude_from_totals: { type: "boolean", description: "Exclude from totals" },
               archived:            { type: "boolean", description: "Whether the category is archived" },
               group_id:            { type: "integer", description: "Parent group ID" },
               order:               { type: "integer", description: "Display order" }
             },
             required: ["id"]
           } do |args, client|
        id   = args["id"]
        body = args.slice("name", "description", "is_income", "exclude_from_budget",
                          "exclude_from_totals", "archived", "group_id", "order")
        result = client.put("/categories/#{id}", body)
        text_response(result)
      end

      tool "delete_category",
           description: "Delete a category by ID",
           input_schema: {
             properties: {
               id:    { type: "integer", description: "Category ID to delete" },
               force: { type: "boolean", description: "Force delete even if category has dependencies" }
             },
             required: ["id"]
           } do |args, client|
        id     = args["id"]
        params = args["force"] ? { force: true } : {}
        client.delete("/categories/#{id}", params)
        { content: [{ type: "text", text: "Category #{id} deleted successfully." }] }
      end
    end
  end
end
