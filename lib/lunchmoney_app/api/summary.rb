# frozen_string_literal: true

module LunchMoneyApp
  module Api
    class Summary
      def self.get_budget_summary(start_date, end_date, params = {})
        api = LunchMoney::SummaryApi.new
        api.get_budget_summary(start_date, end_date, **params.transform_keys(&:to_sym))
      end
    end
  end
end
