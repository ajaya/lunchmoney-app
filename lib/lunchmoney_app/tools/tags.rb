# frozen_string_literal: true

module LunchMoneyApp
  module Tools
    class Tags < LunchMoneyApp::Tool
      tool "get_all_tags", description: "Get all tags" do |_args|
        text_response(Api::Tags.list)
      end

      tool "get_tag",
           description: "Get a single tag by ID",
           input_schema: {
             properties: { id: { type: "integer", description: "Tag ID" } },
             required:   ["id"]
           } do |args|
        text_response(Api::Tags.get(args["id"]))
      end

      tool "create_tag",
           description: "Create a new tag",
           input_schema: {
             properties: {
               name:             { type: "string",  description: "Tag name (1-100 chars, must be unique)" },
               description:      { type: "string",  description: "Tag description (max 200 chars)" },
               text_color:       { type: "string",  description: "Text color hex code" },
               background_color: { type: "string",  description: "Background color hex code" },
               archived:         { type: "boolean", description: "Whether the tag is archived" }
             },
             required: ["name"]
           } do |args|
        text_response(Api::Tags.create(args))
      end

      tool "update_tag",
           description: "Update an existing tag",
           input_schema: {
             properties: {
               id:               { type: "integer", description: "Tag ID to update" },
               name:             { type: "string",  description: "Tag name (1-100 chars)" },
               description:      { type: "string",  description: "Tag description (max 200 chars)" },
               text_color:       { type: "string",  description: "Text color hex code" },
               background_color: { type: "string",  description: "Background color hex code" },
               archived:         { type: "boolean", description: "Whether the tag is archived" }
             },
             required: ["id"]
           } do |args|
        id = args["id"]
        fields = args.reject { |k, _| k == "id" }
        text_response(Api::Tags.update(id, fields))
      end

      tool "delete_tag",
           description: "Delete a tag by ID",
           input_schema: {
             properties: {
               id:    { type: "integer", description: "Tag ID to delete" },
               force: { type: "boolean", description: "Force delete even if tag is in use" }
             },
             required: ["id"]
           } do |args|
        Api::Tags.delete(args["id"], force: args["force"] || false)
        { content: [{ type: "text", text: "Tag #{args["id"]} deleted successfully." }] }
      end
    end
  end
end
