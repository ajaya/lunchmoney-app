# frozen_string_literal: true

module LunchMoneyMcp
  module Tools
    class Tags < LunchMoneyMcp::Tool
      tool "get_all_tags", description: "Get all tags" do |_args, client|
        result = client.get("/tags")
        text_response(result)
      end

      tool "get_tag",
           description: "Get a single tag by ID",
           input_schema: {
             properties: { id: { type: "integer", description: "Tag ID" } },
             required:   ["id"]
           } do |args, client|
        result = client.get("/tags/#{args["id"]}")
        text_response(result)
      end

      tool "create_tag",
           description: "Create a new tag",
           input_schema: {
             properties: {
               name:             { type: "string", description: "Tag name" },
               description:      { type: "string", description: "Tag description" },
               text_color:       { type: "string", description: "Text color hex code" },
               background_color: { type: "string", description: "Background color hex code" }
             },
             required: ["name"]
           } do |args, client|
        body   = args.slice("name", "description", "text_color", "background_color")
        result = client.post("/tags", body)
        text_response(result)
      end

      tool "update_tag",
           description: "Update an existing tag",
           input_schema: {
             properties: {
               id:               { type: "integer", description: "Tag ID to update" },
               name:             { type: "string",  description: "Tag name" },
               description:      { type: "string",  description: "Tag description" },
               text_color:       { type: "string",  description: "Text color hex code" },
               background_color: { type: "string",  description: "Background color hex code" },
               archived:         { type: "boolean", description: "Whether the tag is archived" }
             },
             required: ["id"]
           } do |args, client|
        id     = args["id"]
        body   = args.slice("name", "description", "text_color", "background_color", "archived")
        result = client.put("/tags/#{id}", body)
        text_response(result)
      end

      tool "delete_tag",
           description: "Delete a tag by ID",
           input_schema: {
             properties: {
               id:    { type: "integer", description: "Tag ID to delete" },
               force: { type: "boolean", description: "Force delete even if tag has dependencies" }
             },
             required: ["id"]
           } do |args, client|
        id     = args["id"]
        params = args["force"] ? { force: true } : {}
        client.delete("/tags/#{id}", params)
        { content: [{ type: "text", text: "Tag #{id} deleted successfully." }] }
      end
    end
  end
end
