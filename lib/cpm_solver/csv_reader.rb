# frozen_string_literal: true

require "csv"
require_relative "program"
require_relative "activity"

module CpmSolver
  class CsvReader
    def self.read(file_path)
      new(file_path).read
    end

    def initialize(file_path)
      @file_path = file_path
      @program = Program.new(File.basename(file_path, ".*"))
      @activities_map = {}
    end

    def read
      validate_headers
      CSV.foreach(@file_path, headers: true) do |row|
        activity = create_activity(row)
        @activities_map[activity.reference] = activity
        @program.add_activitity(activity)

        predecessors = row["predecessors"]&.split || []
        @program.add_predecessors(activity, predecessors.map { |ref| @activities_map[ref] })
      end
      @program
    end

    private

    def create_activity(row)
      duration = row["duration"].to_s.strip
      duration = duration.empty? ? 0 : duration.to_i

      Activity.new(
        row["reference"],
        row["name"],
        duration
      )
    end

    def validate_headers
      headers = CSV.read(@file_path, headers: true).headers
      required_headers = %w[reference name duration predecessors]
      missing_headers = required_headers - headers

      return if missing_headers.empty?

      raise "Missing required headers: #{missing_headers.join(', ')}"
    end
  end
end
