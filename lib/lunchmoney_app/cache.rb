# frozen_string_literal: true

require "sequel"
require "json"

module LunchMoneyApp
  class Cache
    TABLES = %i[transactions categories tags plaid_accounts
                manual_accounts recurring_items budgets users].freeze

    attr_reader :db

    def initialize(db_path = nil)
      db_path ||= LunchMoneyApp.configuration.cache_db_path
      db_path = db_path.sub("~", Dir.home) if db_path.start_with?("~")
      FileUtils.mkdir_p(File.dirname(db_path))
      @db = Sequel.sqlite(db_path)
      @db.loggers = [LunchMoneyApp.logger]
      @db.sql_log_level = :debug
      create_tables!
      reconnect_models!
      LunchMoneyApp.logger.info { "Cache initialized at #{db_path}" }
    end

    def get(table, id)
      row = @db[table].where(id: id).first
      return nil unless row

      JSON.parse(row[:data])
    end

    def get_all(table)
      @db[table].map { |row| JSON.parse(row[:data]) }
    end

    def put(table, id, data)
      json = data.is_a?(String) ? data : data.to_json
      @db[table].insert_conflict(:replace).insert(
        id: id, data: json, synced_at: Time.now
      )
    end

    def put_all(table, records)
      @db.transaction do
        records.each do |r|
          id = r["id"] || r[:id]
          put(table, id, r) if id
        end
      end
    end

    def remove(table, id)
      @db[table].where(id: id).delete
    end

    def clear(table)
      @db[table].delete
    end

    private

    def create_tables!
      TABLES.each do |t|
        @db.create_table?(t) do
          Integer :id, primary_key: true
          column :data, :text, null: false
          DateTime :synced_at, null: false
        end
      end
    end

    def reconnect_models!
      Api.constants.each do |name|
        klass = Api.const_get(name)
        next unless klass.is_a?(Class) && klass < Sequel::Model

        klass.dataset = @db[klass.table_name]
      end
    end
  end
end
