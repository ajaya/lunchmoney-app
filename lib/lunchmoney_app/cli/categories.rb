# frozen_string_literal: true

require "thor"
require "terminal-table"

module LunchMoneyApp
  module Cli
    class Categories < Base
      class_option :json, type: :boolean, default: false, desc: "Output in JSON format"

      desc "list", "List categories"
      option :format, type: :string, enum: %w[nested flattened], desc: "Response format (nested or flattened)"
      option :is_group, type: :boolean, desc: "Filter to only groups (true) or only categories (false)"
      def list
        ensure_setup!
        params = options.slice("format", "is_group")
        result = Api::Categories.list(params)
        out.render(result) { |data| format_category_list(data["categories"] || data[:categories]) }
      end

      desc "show ID", "Show a single category"
      def show(id)
        ensure_setup!
        result = Api::Categories.get(id.to_i)
        out.render(result) { |data| JSON.pretty_generate(data) }
      end

      desc "create", "Create a category"
      option :name, type: :string, required: true, desc: "Category name"
      option :description, type: :string, desc: "Category description"
      option :is_income, type: :boolean, desc: "Whether this is an income category"
      option :exclude_from_budget, type: :boolean, desc: "Exclude from budget"
      option :exclude_from_totals, type: :boolean, desc: "Exclude from totals"
      option :is_group, type: :boolean, desc: "Create as a category group"
      option :group_id, type: :numeric, desc: "Parent group ID"
      option :archived, type: :boolean, desc: "Whether the category is archived"
      def create
        ensure_setup!
        fields = options.slice(
          "name", "description", "is_income", "exclude_from_budget",
          "exclude_from_totals", "is_group", "group_id", "archived"
        )
        result = Api::Categories.create(fields)
        out.render(result, "Created category: #{result["name"]} (id: #{result["id"]})")
      end

      desc "update ID", "Update a category"
      option :name, type: :string, desc: "Category name"
      option :description, type: :string, desc: "Category description"
      option :is_income, type: :boolean, desc: "Whether this is an income category"
      option :exclude_from_budget, type: :boolean, desc: "Exclude from budget"
      option :exclude_from_totals, type: :boolean, desc: "Exclude from totals"
      option :archived, type: :boolean, desc: "Whether the category is archived"
      option :group_id, type: :numeric, desc: "Parent group ID"
      def update(id)
        ensure_setup!
        fields = options.slice(
          "name", "description", "is_income", "exclude_from_budget",
          "exclude_from_totals", "archived", "group_id"
        )
        if fields.empty?
          abort "No fields to update. Use --name, --description, --is-income, --exclude-from-budget, --exclude-from-totals, --archived, or --group-id"
        end
        result = Api::Categories.update(id.to_i, fields)
        out.render(result, "Category #{id} updated")
      end

      desc "delete ID", "Delete a category"
      option :force, type: :boolean, desc: "Force delete even if category has dependencies"
      def delete(id)
        ensure_setup!
        Api::Categories.delete(id.to_i, force: options[:force] || false)
        out.render({ deleted: true, id: id.to_i }, "Category #{id} deleted")
      end

      private

      def out
        @out ||= Output.new(json: options[:json] || (parent_options && parent_options[:json]))
      end

      def format_category_list(categories)
        return "No categories found." if categories.nil? || categories.empty?

        rows = []
        categories.each do |cat|
          name = cat["name"] || "Unknown"
          flags = []
          flags << "group" if cat["is_group"]
          flags << "income" if cat["is_income"]
          flags << "archived" if cat["archived"]
          flags << "excl budget" if cat["exclude_from_budget"]
          flags << "excl totals" if cat["exclude_from_totals"]
          rows << [cat["id"], name, flags.join(", ")]
          next unless cat["children"]

          cat["children"].each do |child|
            rows << ["", "  #{child["name"]}", ""]
          end
        end

        ::Terminal::Table.new(headings: %w[ID Name Flags], rows: rows).to_s
      end
    end
  end
end
