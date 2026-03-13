# frozen_string_literal: true

module LunchMoneyApp
  module Api
    class Tags < Sequel::Model(:tags)
      include Base

      def self.list
        api = LunchMoney::TagsApi.new
        result = api.get_all_tags
        sync_collection(result, :tags)
        result
      end

      def self.get(id)
        api = LunchMoney::TagsApi.new
        result = api.get_tag_by_id(id)
        sync_record(id, result)
        result
      end

      def self.create(fields)
        api = LunchMoney::TagsApi.new
        api.create_tag(fields)
      end

      def self.update(id, fields)
        api = LunchMoney::TagsApi.new
        api.update_tag(id, fields)
      end

      def self.delete(id, force: false)
        remove_cached(id)
        api = LunchMoney::TagsApi.new
        opts = force ? { force: true } : {}
        api.delete_tag(id, opts)
      end
    end
  end
end
