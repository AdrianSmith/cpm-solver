require_relative 'solver'
require 'set'

module CpmSolver
  module Solvers
    class Topological < Solver
      protected

      def calculate_early_times
        sorted_activities = topological_sort

        # Initialize all early starts to 0
        program.activities.each_value do |activity|
          activity.early_start = 0
          activity.early_finish = activity.duration
        end

        # Forward pass through sorted activities
        sorted_activities.each do |activity|
          max_predecessor_finish = activity.predecessors.map do |pred_ref|
            program.activities[pred_ref].early_finish
          end.compact.max || 0

          activity.early_start = max_predecessor_finish
          activity.early_finish = activity.early_start + activity.duration
        end
      end

      def calculate_late_times
        return unless program.activities.values.all? { |a| a.early_finish }

        project_end = program.activities.values.map(&:early_finish).max
        sorted_activities = topological_sort.reverse

        # Initialize all activities
        program.activities.each_value do |activity|
          if activity.successors.empty?
            activity.late_finish = project_end
            activity.late_start = activity.late_finish - activity.duration
          end
        end

        # Backward pass through reverse sorted activities
        sorted_activities.each do |activity|
          next if activity.successors.empty?

          min_successor_start = activity.successors.map do |succ_ref|
            program.activities[succ_ref].late_start
          end.min

          activity.late_finish = min_successor_start
          activity.late_start = activity.late_finish - activity.duration
        end
      end

      private

      def topological_sort
        visited = Set.new
        temp = Set.new
        order = []

        program.activities.each_value do |activity|
          visit(activity, visited, temp, order) unless visited.include?(activity)
        end

        order
      end

      def visit(activity, visited, temp, order)
        return if visited.include?(activity)
        raise CyclicDependencyError, "Cycle detected in activity dependencies" if temp.include?(activity)

        temp.add(activity)

        activity.successors.each do |succ_ref|
          successor = program.activities[succ_ref]
          visit(successor, visited, temp, order) unless visited.include?(successor)
        end

        temp.delete(activity)
        visited.add(activity)
        order.unshift(activity)
      end
    end
  end
end
