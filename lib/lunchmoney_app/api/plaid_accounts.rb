# frozen_string_literal: true

module LunchMoneyApp
  module Api
    class PlaidAccounts < Sequel::Model(:plaid_accounts)
      include Base

      def self.list
        api = LunchMoney::PlaidAccountsApi.new
        result = api.get_all_plaid_accounts
        sync_collection(result, :plaid_accounts)
        result
      end

      def self.get(id)
        api = LunchMoney::PlaidAccountsApi.new
        result = api.get_plaid_account_by_id(id)
        sync_record(id, result)
        result
      end

      def self.fetch(start_date: nil, end_date: nil, id: nil)
        api = LunchMoney::PlaidAccountsApi.new
        opts = {}
        opts[:start_date] = start_date if start_date
        opts[:end_date] = end_date if end_date
        opts[:id] = id if id
        api.trigger_plaid_account_fetch(**opts)
      end
    end
  end
end
