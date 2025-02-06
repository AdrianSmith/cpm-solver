# Ruby implementation of Floyd Warshall Algorithm
module CpmSolver
  module Solvers
    class FloydWarshall < Solver
      INF = Float::INFINITY

      protected

      def calculate_early_times
        graph = initialize_early_times_graph
        distances = solve_floyd_warshall(graph)
        start_vertex = find_start_vertex

        program.activities.each_value do |activity|
          vertex_index = activity_to_vertex_index(activity)
          early_time = distances[start_vertex][vertex_index]
          activity.early_start = early_time == -INF ? 0 : early_time
          activity.early_finish = activity.early_start + activity.duration
        end
      end

      def calculate_late_times
        return unless program.activities.values.all? { |a| a.early_finish }

        project_end = program.activities.values.map(&:early_finish).max
        graph = initialize_late_times_graph
        distances = solve_floyd_warshall(graph)
        end_vertex = find_end_vertex

        program.activities.each_value do |activity|
          vertex_index = activity_to_vertex_index(activity)
          path_length = distances[vertex_index][end_vertex]
          activity.late_finish = project_end - (path_length == -INF ? 0 : path_length)
          activity.late_start = activity.late_finish - activity.duration
        end
      end

      private

      def solve_floyd_warshall(graph)
        vertex_count = program.activities.size
        dist = Array.new(vertex_count) { |i| Array.new(vertex_count) { |j| graph[i][j] } }

        vertex_count.times do |k|
          vertex_count.times do |i|
            vertex_count.times do |j|
              if dist[i][k] != -INF && dist[k][j] != -INF
                new_dist = dist[i][k] + dist[k][j]
                if new_dist > dist[i][j] || dist[i][j] == -INF
                  dist[i][j] = new_dist
                end
              end
            end
          end
        end

        dist
      end

      def initialize_early_times_graph
        size = program.activities.size
        graph = Array.new(size) { Array.new(size, -INF) }

        # Initialize diagonal
        size.times { |i| graph[i][i] = 0 }

        # Add edges from predecessors to activities
        program.activities.each_value do |activity|
          to_idx = activity_to_vertex_index(activity)

          activity.predecessors.each do |pred_ref|
            pred = program.activities[pred_ref]
            from_idx = activity_to_vertex_index(pred)
            graph[from_idx][to_idx] = pred.duration
          end
        end

        # Find start vertices (those with no predecessors)
        start_vertices = program.activities.values
          .select { |a| a.predecessors.empty? }
          .map { |a| activity_to_vertex_index(a) }

        # If we have multiple start vertices, connect them all to a single one
        if start_vertices.size > 1
          main_start = start_vertices.first
          start_vertices[1..-1].each do |vertex|
            # Connect other start vertices to the main start vertex
            graph[main_start][vertex] = 0
          end
        end

        graph
      end

      def initialize_late_times_graph
        size = program.activities.size
        graph = Array.new(size) { Array.new(size, -INF) }

        # Initialize diagonal
        size.times { |i| graph[i][i] = 0 }

        # Add edges from activities to successors (reversed from early times)
        program.activities.each_value do |activity|
          from_idx = activity_to_vertex_index(activity)

          activity.successors.each do |succ_ref|
            succ = program.activities[succ_ref]
            to_idx = activity_to_vertex_index(succ)
            # For late times, we use the successor's duration
            graph[from_idx][to_idx] = succ.duration
          end
        end

        graph
      end

      def activity_to_vertex_index(activity)
        program.activities.keys.index(activity.reference)
      end

      def find_start_vertex
        program.activities.values.find_index { |a| a.predecessors.empty? }
      end

      def find_end_vertex
        program.activities.values.find_index { |a| a.successors.empty? }
      end
    end
  end
end
