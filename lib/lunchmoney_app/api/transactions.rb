# frozen_string_literal: true

module LunchMoneyApp
  module Api
    class Transactions < Sequel::Model(:transactions)
      include Base

      def self.list(params = {})
        api = LunchMoney::TransactionsBulkApi.new
        result = api.get_all_transactions(**params.transform_keys(&:to_sym))
        sync_collection(result, :transactions)
        result
      end

      def self.get(id)
        api = LunchMoney::TransactionsApi.new
        result = api.get_transaction_by_id(id)
        sync_record(id, result)
        result
      end

      def self.create(transactions:, apply_rules: nil, skip_duplicates: nil, skip_balance_update: nil)
        api = LunchMoney::TransactionsBulkApi.new
        req = LunchMoney::CreateNewTransactionsRequest.new(
          transactions: transactions,
          apply_rules: apply_rules,
          skip_duplicates: skip_duplicates,
          skip_balance_update: skip_balance_update
        )
        api.create_new_transactions(req)
      end

      def self.update(id, fields)
        api = LunchMoney::TransactionsApi.new
        api.update_transaction(id, fields)
      end

      def self.update_bulk(transactions)
        api = LunchMoney::TransactionsBulkApi.new
        req = LunchMoney::UpdateTransactionsRequest.new(transactions: transactions)
        api.update_transactions(req)
      end

      def self.delete(id)
        remove_cached(id)
        api = LunchMoney::TransactionsApi.new
        api.delete_transaction_by_id(id)
      end

      def self.delete_bulk(ids)
        ids.each { |id| remove_cached(id) }
        api = LunchMoney::TransactionsBulkApi.new
        req = LunchMoney::DeleteTransactionsRequest.new(ids: ids)
        api.delete_transactions(req)
      end

      def self.split(id, child_transactions)
        api = LunchMoney::TransactionsSplitApi.new
        req = LunchMoney::SplitTransactionRequest.new(child_transactions: child_transactions)
        api.split_transaction(id, req)
      end

      def self.unsplit(id)
        api = LunchMoney::TransactionsSplitApi.new
        api.unsplit_transaction(id)
      end

      def self.group(ids:, date:, payee:, category_id: nil, notes: nil, status: nil, tag_ids: nil)
        api = LunchMoney::TransactionsGroupApi.new
        req = LunchMoney::GroupTransactionsRequest.new(
          ids: ids, date: date, payee: payee,
          category_id: category_id, notes: notes,
          status: status, tag_ids: tag_ids
        )
        api.group_transactions(req)
      end

      def self.ungroup(id)
        api = LunchMoney::TransactionsGroupApi.new
        api.ungroup_transactions(id)
      end

      def self.attach_file(transaction_id, file:, notes: nil)
        api = LunchMoney::TransactionsFilesApi.new
        opts = {}
        opts[:notes] = notes if notes
        api.attach_file_to_transaction(transaction_id, file, opts)
      end

      def self.get_attachment_url(file_id)
        api = LunchMoney::TransactionsFilesApi.new
        api.get_transaction_attachment_url(file_id)
      end

      def self.delete_attachment(file_id)
        api = LunchMoney::TransactionsFilesApi.new
        api.delete_transaction_attachment(file_id)
      end
    end
  end
end
