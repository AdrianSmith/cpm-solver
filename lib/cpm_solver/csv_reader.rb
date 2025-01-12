

require "csv"
require_relative "program"
require_relative "activity"

module CpmSolver
  # Reads a CSV file and creates a Program object
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
      create_activities
      create_predecessors
      @program
    end

    private

    def create_activities
      CSV.foreach(@file_path, headers: true) do |row|
        activity = create_activity(row)
        @activities_map[activity.reference] = activity
        @program.add_activitity(activity)
      end
    end

    def create_predecessors
      CSV.foreach(@file_path, headers: true) do |row|
        activity = @activities_map[row["reference"]]
        predecessors = row["predecessors"]&.split(/,\s*/) || []
        @program.add_predecessors(activity, predecessors.map { |ref| @activities_map[ref] })
      end
    end

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
