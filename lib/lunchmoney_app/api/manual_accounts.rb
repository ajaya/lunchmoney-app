# frozen_string_literal: true

module LunchMoneyApp
  module Api
    class ManualAccounts < Sequel::Model(:manual_accounts)
      include Base

      def self.list
        api = LunchMoney::ManualAccountsApi.new
        result = api.get_all_manual_accounts
        sync_collection(result, :manual_accounts, :assets)
        result
      end

      def self.get(id)
        api = LunchMoney::ManualAccountsApi.new
        result = api.get_manual_account_by_id(id)
        sync_record(id, result)
        result
      end

      def self.create(fields)
        api = LunchMoney::ManualAccountsApi.new
        api.create_manual_account(fields)
      end

      def self.update(id, fields)
        api = LunchMoney::ManualAccountsApi.new
        api.update_manual_account(id, fields)
      end

      def self.delete(id, delete_items: false, delete_balance_history: false)
        remove_cached(id)
        api = LunchMoney::ManualAccountsApi.new
        api.delete_manual_account(id, delete_items: delete_items, delete_balance_history: delete_balance_history)
      end
    end
  end
end
