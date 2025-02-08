require_relative "solver"

module CpmSolver
  module Solvers
    class CriticalPath < Solver
      protected

      # Calculate early start and finish times using forward pass
      def calculate_early_times
        recalc_early_times = true

        while recalc_early_times
          recalc_early_times = false
          program.activities.each_value.with_index do |activity, index|
            if index.zero?
              activity.early_start = 0
            else
              # Check if predecessors uncalculated
              activity.predecessors.each do |predecessor|
                recalc_early_times = true if program.activities[predecessor].early_finish.nil?
              end

              predecessors = activity.predecessors.map { |ref| program.activities[ref] }
              latest_finish_date = predecessors.map(&:early_finish).compact.max
              activity.early_start = latest_finish_date
            end
            activity.early_finish = activity.early_start + activity.duration
          end
        end
      end

      # Calculate late start and finish times using backward pass
      def calculate_late_times
        # First, set all activities' late times to nil
        program.activities.each_value do |activity|
          activity.late_start = nil
          activity.late_finish = nil
        end

        # Initialize end activities with their early finish times
        program.end_activities.each_value do |activity|
          activity.late_finish = activity.early_finish
          activity.late_start = activity.late_finish - activity.duration
        end

        # Keep processing until all activities have been calculated
        until program.activities.values.all? { |a| a.late_start && a.late_finish }
          program.activities.values.reverse_each do |activity|
            # Skip if already calculated
            next if activity.late_start && activity.late_finish
            # Skip if any successor hasn't been calculated yet
            next if activity.successors.any? { |ref| program.activities[ref].late_start.nil? }

            # All successors have been calculated, so we can calculate this activity
            earliest_successor_start = activity.successors.map { |ref| program.activities[ref].late_start }.min
            activity.late_finish = earliest_successor_start
            activity.late_start = activity.late_finish - activity.duration
          end
        end
      end
    end
  end
end
