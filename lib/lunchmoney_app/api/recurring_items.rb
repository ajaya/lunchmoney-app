# frozen_string_literal: true

module LunchMoneyApp
  module Api
    class RecurringItems < Sequel::Model(:recurring_items)
      include Base

      def self.list(params = {})
        api = LunchMoney::RecurringItemsApi.new
        result = api.get_all_recurring(**params.transform_keys(&:to_sym))
        sync_collection(result, :recurring_items, :recurring_expenses)
        result
      end

      def self.get(id, params = {})
        api = LunchMoney::RecurringItemsApi.new
        result = api.get_recurring_by_id(id, **params.transform_keys(&:to_sym))
        sync_record(id, result)
        result
      end
    end
  end
end
