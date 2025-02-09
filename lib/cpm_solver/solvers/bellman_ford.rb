module CpmSolver
  module Solvers
    class BellmanFord < Solver
      INF = Float::INFINITY

      protected

      def calculate_early_times
        # Initialize distances
        distances = {}
        program.activities.each_value do |activity|
          distances[activity.reference] = -INF
        end

        # Find start activities and set their distance to 0
        start_activities = program.activities.values.select { |a| a.predecessors.empty? }
        start_activities.each { |activity| distances[activity.reference] = 0 }

        # Relax edges |V| - 1 times
        (program.activities.size - 1).times do
          program.activities.each_value do |activity|
            activity.successors.each do |succ_ref|
              successor = program.activities[succ_ref]
              if distances[activity.reference] != -INF
                new_distance = distances[activity.reference] + activity.duration
                if new_distance > distances[successor.reference]
                  distances[successor.reference] = new_distance
                end
              end
            end
          end
        end

        # Set early times for all activities
        program.activities.each_value do |activity|
          activity.early_start = distances[activity.reference] == -INF ? 0 : distances[activity.reference]
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

        # Find end activities and set their distance to project end
        end_activities = program.activities.values.select { |a| a.successors.empty? }
        end_activities.each { |activity| distances[activity.reference] = project_end }

        # Relax edges |V| - 1 times
        (program.activities.size - 1).times do
          program.activities.each_value do |activity|
            activity.predecessors.each do |pred_ref|
              predecessor = program.activities[pred_ref]
              if distances[activity.reference] != INF
                new_distance = distances[activity.reference] - activity.duration
                if new_distance < distances[predecessor.reference]
                  distances[predecessor.reference] = new_distance
                end
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
