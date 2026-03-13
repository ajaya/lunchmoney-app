# frozen_string_literal: true

module LunchMoneyApp
  module Api
    class Categories < Sequel::Model(:categories)
      include Base

      def self.list(params = {})
        api = LunchMoney::CategoriesApi.new
        result = api.get_all_categories(**params.transform_keys(&:to_sym))
        sync_collection(result, :categories)
        result
      end

      def self.get(id)
        api = LunchMoney::CategoriesApi.new
        result = api.get_category_by_id(id)
        sync_record(id, result)
        result
      end

      def self.create(fields)
        api = LunchMoney::CategoriesApi.new
        api.create_category(fields)
      end

      def self.update(id, fields)
        api = LunchMoney::CategoriesApi.new
        api.update_category(id, fields)
      end

      def self.delete(id, force: false)
        remove_cached(id)
        api = LunchMoney::CategoriesApi.new
        opts = force ? { force: true } : {}
        api.delete_category(id, opts)
      end
    end
  end
end
