require "csv"
require_relative "../core/activity"

module CpmSolver
  module IO
    class CsvReader
      def initialize(file_path)
        @file_path = file_path
      end

      def read
        activities = {}
        CSV.foreach(@file_path, headers: true, header_converters: :downcase) do |row|
          # Map CSV columns to activity attributes
          reference = row["reference"]
          name = row["name"]
          duration = row["duration"].to_i
          predecessors = row["predecessors"]&.split(/,\s*/)&.map(&:strip) || []

          activity = Core::Activity.new(reference, name, duration)
          activities[reference] = { activity:, predecessors: }
        end

        # Link predecessors
        activities.each do |_reference, data|
          data[:predecessors].each do |predecessor_ref|
            next if predecessor_ref.nil? || predecessor_ref.empty?
            predecessor = activities[predecessor_ref]
            raise "Predecessor #{predecessor_ref} not found" unless predecessor

            data[:activity].add_predecessor(predecessor[:activity])
            predecessor[:activity].add_successor(data[:activity])
          end
        end

        activities.transform_values { |data| data[:activity] }
      end
    end
  end
end
