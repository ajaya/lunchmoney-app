# frozen_string_literal: true

module LunchMoneyApp
  module Tools
    class Categories < LunchMoneyApp::Tool
      tool "get_all_categories",
           description: "Get all categories, optionally nested or flattened",
           input_schema: {
             properties: {
               format:   { type: "string", description: "Response format", enum: %w[nested flattened] },
               is_group: { type: "boolean", description: "Filter to only category groups (true) or only categories (false)" }
             }
           } do |args|
        text_response(Api::Categories.list(args))
      end

      tool "get_category",
           description: "Get a single category by ID",
           input_schema: {
             properties: { id: { type: "integer", description: "Category ID" } },
             required:   ["id"]
           } do |args|
        text_response(Api::Categories.get(args["id"]))
      end

      tool "create_category",
           description: "Create a new category or category group",
           input_schema: {
             properties: {
               name:                { type: "string",  description: "Category name (1-100 chars)" },
               description:         { type: "string",  description: "Category description (max 200 chars)" },
               is_income:           { type: "boolean", description: "Whether this is an income category" },
               exclude_from_budget: { type: "boolean", description: "Exclude from budget" },
               exclude_from_totals: { type: "boolean", description: "Exclude from totals" },
               is_group:            { type: "boolean", description: "Whether this is a category group" },
               group_id:            { type: "integer", description: "Parent group ID" },
               archived:            { type: "boolean", description: "Whether the category is archived" },
               children:            { type: "array",   description: "Category IDs or names to add to the group (only when is_group is true)" },
               order:               { type: "integer", description: "Display order" },
               collapsed:           { type: "boolean", description: "Whether the category is collapsed in the GUI" }
             },
             required: ["name"]
           } do |args|
        text_response(Api::Categories.create(args))
      end

      tool "update_category",
           description: "Update an existing category or category group",
           input_schema: {
             properties: {
               id:                  { type: "integer", description: "Category ID to update" },
               name:                { type: "string",  description: "Category name (1-100 chars)" },
               description:         { type: "string",  description: "Category description (max 200 chars)" },
               is_income:           { type: "boolean", description: "Whether this is an income category" },
               exclude_from_budget: { type: "boolean", description: "Exclude from budget" },
               exclude_from_totals: { type: "boolean", description: "Exclude from totals" },
               archived:            { type: "boolean", description: "Whether the category is archived" },
               group_id:            { type: "integer", description: "Parent group ID" },
               children:            { type: "array",   description: "Category IDs or names to replace children (only for category groups)" },
               order:               { type: "integer", description: "Display order" },
               collapsed:           { type: "boolean", description: "Whether the category is collapsed in the GUI" }
             },
             required: ["id"]
           } do |args|
        id = args["id"]
        fields = args.reject { |k, _| k == "id" }
        text_response(Api::Categories.update(id, fields))
      end

      tool "delete_category",
           description: "Delete a category by ID",
           input_schema: {
             properties: {
               id:    { type: "integer", description: "Category ID to delete" },
               force: { type: "boolean", description: "Force delete even if category has dependencies" }
             },
             required: ["id"]
           } do |args|
        Api::Categories.delete(args["id"], force: args["force"] || false)
        { content: [{ type: "text", text: "Category #{args["id"]} deleted successfully." }] }
      end
    end
  end
end
