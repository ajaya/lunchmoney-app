# frozen_string_literal: true

module LunchMoneyApp
  module Api
    module Base
      def self.included(model)
        model.unrestrict_primary_key
        model.extend(ClassMethods)
      end

      def parsed_data
        JSON.parse(self[:data])
      end

      module ClassMethods
        def sync_record(id, record)
          return unless id

          data = serialize_response(record)
          dataset.insert_conflict(:replace).insert(
            id: id, data: data.to_json, synced_at: Time.now
          )
          LunchMoneyApp.logger.debug { "#{name} cache write id=#{id}" }
        end

        def sync_collection(result, *keys)
          items = nil
          keys.each do |key|
            items = extract_items(result, key)
            break if items
          end
          return unless items

          items.each do |item|
            id = extract_id(item)
            sync_record(id, item) if id
          end
          LunchMoneyApp.logger.debug { "#{name} synced #{items.size} records" }
        end

        def remove_cached(id)
          where(id: id).delete
          LunchMoneyApp.logger.debug { "#{name} cache remove id=#{id}" }
        end

        def cached(id, *path, fetch: false)
          return nil unless id

          row = self[id]
          if row
            LunchMoneyApp.logger.debug { "#{name} cache hit id=#{id}" }
            data = row.parsed_data
          elsif fetch && respond_to?(:get)
            LunchMoneyApp.logger.debug { "#{name} cache miss id=#{id}, fetching" }
            result = get(id)
            if result
              sync_record(id, result)
              data = serialize_response(result)
            else
              LunchMoneyApp.logger.debug { "#{name} fetch failed for id=#{id}" }
              return nil
            end
          else
            LunchMoneyApp.logger.debug { "#{name} cache miss id=#{id}" }
            return nil
        end
          path.empty? ? data : data&.dig(*path)
        end

        def cached_all
          all.map(&:parsed_data)
        end

        private

        def serialize_response(record)
          record.respond_to?(:to_hash) ? record.to_hash : record
        end

        def extract_id(record)
          if record.respond_to?(:id)
            record.id
          elsif record.is_a?(Hash)
            record["id"] || record[:id]
          end
        end

        def extract_items(result, key)
          val = if result.respond_to?(key)
                  result.send(key)
                elsif result.is_a?(Hash)
                  result[key.to_s] || result[key]
                end
          val
        end
      end
    end
  end
end
