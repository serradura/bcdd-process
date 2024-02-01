# frozen_string_literal: true

class BCDD::Result::TransitionsRecord < ActiveRecord::Base
  self.table_name = 'bcdd_result_transitions'

  class Listener
    include ::BCDD::Result::Transitions::Listener

    def on_finish(transitions:)
      metadata = transitions[:metadata]
      root_name = transitions.dig(:records, 0, :root, :name) || 'Unknown'

      records = transitions[:records].map do |record|
        record.deep_transform_values do |value|
          value.is_a?(::BCDD::Process) ? value.class.name : value
        end
      end

      BCDD::Result::TransitionsRecord.create(
        root_name: root_name,
        duration: metadata[:duration],
        trace_id: metadata[:trace_id],
        ids_tree: metadata[:ids_tree],
        ids_matrix: metadata[:ids_matrix],
        version: transitions[:version],
        records: records
      )
    rescue ::StandardError => e
      err = "#{e.message} (#{e.class}); Backtrace: #{e.backtrace.join(', ')}"

      ::Kernel.warn "Error on BCDD::Result::TransitionsRecord::Listener#on_finish: #{err}"
    end
  end
end
