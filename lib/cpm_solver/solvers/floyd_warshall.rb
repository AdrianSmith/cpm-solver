# Ruby implementation of Floyd Warshall Algorithm
class FloydWarshall
  INF = Float::INFINITY

  def initialize(graph)
    @vertex_count = graph.length
    @graph = graph
  end

  def solve
    # Initialize distance matrix as a deep copy of the input graph
    dist = @graph.map(&:dup)

    # Add vertices one by one to the set of intermediate vertices
    @vertex_count.times do |k|
      # Pick all vertices as source one by one
      @vertex_count.times do |i|
        # Pick all vertices as destination for the above picked source
        @vertex_count.times do |j|
          # If vertex k is on the shortest path from i to j,
          # then update the value of dist[i][j]
          dist[i][j] = [dist[i][j], dist[i][k] + dist[k][j]].min
        end
      end
    end

    dist
  end

  def print_solution(dist)
    puts "Following matrix shows the shortest distances between every pair of vertices:"
    dist.each do |row|
      row.each do |element|
        if element == INF
          print "INF".rjust(7) + " "
        else
          print element.to_s.rjust(7) + " "
        end
      end
      puts
    end
  end
end

# Example usage:
if $PROGRAM_NAME == __FILE__
  # Example graph representation:
  #                10
  #           (0)------->(3)
  #            |         /|\
  #          5 |          |
  #            |          | 1
  #           \|/         |
  #           (1)------->(2)
  #                3
  graph = [
    [0, 5, FloydWarshall::INF, 10],
    [FloydWarshall::INF, 0, 3, FloydWarshall::INF],
    [FloydWarshall::INF, FloydWarshall::INF, 0, 1],
    [FloydWarshall::INF, FloydWarshall::INF, FloydWarshall::INF, 0]
  ]

  floyd = FloydWarshall.new(graph)
  solution = floyd.solve
  floyd.print_solution(solution)
end
