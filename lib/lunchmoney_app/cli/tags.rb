# frozen_string_literal: true

require "thor"
require "terminal-table"

module LunchMoneyApp
  module Cli
    class Tags < Base
      class_option :json, type: :boolean, default: false, desc: "Output in JSON format"

      desc "list", "List all tags"
      def list
        ensure_setup!
        result = Api::Tags.list
        out.render(result) { |data| format_tag_list(data.is_a?(Hash) ? data["tags"] || data.values.first : data) }
      end

      desc "show ID", "Show a single tag"
      def show(id)
        ensure_setup!
        result = Api::Tags.get(id.to_i)
        out.render(result) { |data| JSON.pretty_generate(data) }
      end

      desc "create", "Create a new tag"
      option :name, type: :string, required: true, desc: "Tag name (1-100 chars)"
      option :description, type: :string, desc: "Tag description (max 200 chars)"
      option :text_color, type: :string, desc: "Text color hex code"
      option :background_color, type: :string, desc: "Background color hex code"
      option :archived, type: :boolean, desc: "Whether the tag is archived"
      def create
        ensure_setup!
        fields = options.slice("name", "description", "text_color", "background_color", "archived")
        result = Api::Tags.create(fields)
        result = LunchMoneyApp::Tool.serialize(result)
        out.render(result, "Created tag: #{result["name"]} (id: #{result["id"]})")
      end

      desc "update ID", "Update a tag"
      option :name, type: :string, desc: "Tag name (1-100 chars)"
      option :description, type: :string, desc: "Tag description (max 200 chars)"
      option :text_color, type: :string, desc: "Text color hex code"
      option :background_color, type: :string, desc: "Background color hex code"
      option :archived, type: :boolean, desc: "Whether the tag is archived"
      def update(id)
        ensure_setup!
        fields = options.slice("name", "description", "text_color", "background_color", "archived")
        if fields.empty?
          abort "No fields to update. Use --name, --description, --text-color, --background-color, or --archived"
        end
        result = Api::Tags.update(id.to_i, fields)
        out.render(result, "Tag #{id} updated")
      end

      desc "delete ID", "Delete a tag"
      option :force, type: :boolean, desc: "Force delete even if tag is in use"
      def delete(id)
        ensure_setup!
        Api::Tags.delete(id.to_i, force: options[:force] || false)
        out.render({ deleted: true, id: id.to_i }, "Tag #{id} deleted")
      end

      private

      def out
        @out ||= Output.new(json: options[:json] || (parent_options && parent_options[:json]))
      end

      def format_tag_list(tags)
        return "No tags found." if tags.nil? || tags.empty?

        rows = tags.map do |tag|
          archived = tag["archived"] ? "[archived]" : ""
          [tag["id"], tag["name"] || "Unknown", tag["description"] || "", archived]
        end
        ::Terminal::Table.new(headings: %w[ID Name Description Status], rows: rows).to_s
      end
    end
  end
end
