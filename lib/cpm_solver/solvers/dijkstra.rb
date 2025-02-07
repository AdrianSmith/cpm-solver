module CpmSolver
  module Solvers
    class Dijkstra < Solver
      INF = Float::INFINITY

      protected

      def calculate_early_times
        # Initialize distances
        distances = {}
        program.activities.each_value do |activity|
          distances[activity.reference] = -INF
        end

        # Find start activities (those with no predecessors)
        start_activities = program.activities.values.select { |a| a.predecessors.empty? }
        start_activities.each { |activity| distances[activity.reference] = 0 }

        # Process activities in order of increasing distance
        queue = start_activities.dup
        while queue.any?
          current = queue.min_by { |a| distances[a.reference] }
          queue.delete(current)

          # Update distances to successors
          current.successors.each do |succ_ref|
            successor = program.activities[succ_ref]
            new_distance = distances[current.reference] + current.duration

            if new_distance > distances[successor.reference]
              distances[successor.reference] = new_distance
              queue << successor unless queue.include?(successor)
            end
          end
        end

        # Set early times for all activities
        program.activities.each_value do |activity|
          activity.early_start = distances[activity.reference]
          activity.early_finish = activity.early_start + activity.duration
        end
      end

      def calculate_late_times
        return unless program.activities.values.all? { |a| a.early_finish }

        project_end = program.activities.values.map(&:early_finish).max
        distances = {}
        program.activities.each_value do |activity|
          distances[activity.reference] = INF
        end

        # Find end activities (those with no successors)
        end_activities = program.activities.values.select { |a| a.successors.empty? }
        end_activities.each do |activity|
          # Set late finish to project end time
          distances[activity.reference] = project_end
        end

        # Process activities in reverse order
        queue = end_activities.dup
        processed = Set.new

        while queue.any?
          current = queue.min_by { |a| -distances[a.reference] }
          queue.delete(current)
          processed.add(current)

          # Update distances to predecessors
          current.predecessors.each do |pred_ref|
            predecessor = program.activities[pred_ref]
            new_distance = distances[current.reference] - current.duration

            if new_distance < distances[predecessor.reference]
              distances[predecessor.reference] = new_distance
              unless processed.include?(predecessor)
                queue << predecessor unless queue.include?(predecessor)
              end
            end
          end
        end

        # Set late times for all activities
        program.activities.each_value do |activity|
          activity.late_finish = distances[activity.reference]
          activity.late_start = activity.late_finish - activity.duration
        end
      end
    end
  end
end
