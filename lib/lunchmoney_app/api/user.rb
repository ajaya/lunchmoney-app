# frozen_string_literal: true

module LunchMoneyApp
  module Api
    class User < Sequel::Model(:users)
      include Base

      def self.get_me
        api = LunchMoney::MeApi.new
        result = api.get_me
        id = extract_id(result)
        sync_record(id, result) if id
        result
      end
    end
  end
end
