require "spec_helper"
require "terminal-table"
require "cpm_solver/visualization/graph_builder"
require "fileutils"

RSpec.describe "Solver Performance Tests", :performance do
  ITERATIONS = 5
  ACTIVITY_COUNT = 250
  MAX_PREDECESSORS = 5
  LAYERS = 20  # Define number of layers for better control

  def generate_large_program
    program = CpmSolver::Core::Program.new("Large Performance Test Program")

    # Create start and end activities
    start_activity = CpmSolver::Core::Activity.new("A0", "Start Activity", rand(1..20))
    end_activity = CpmSolver::Core::Activity.new("A#{ACTIVITY_COUNT-1}", "End Activity", rand(1..20))

    # Create middle activities
    middle_activities = (1...(ACTIVITY_COUNT-1)).map do |i|
      CpmSolver::Core::Activity.new(
        "A#{i}",
        "Activity #{i}",
        rand(1..20)
      )
    end

    # Add all activities to program
    program.add_activity(start_activity)
    middle_activities.each { |activity| program.add_activity(activity) }
    program.add_activity(end_activity)

    # Divide activities into layers (excluding start and end)
    activities_per_layer = middle_activities.size / LAYERS
    layers = middle_activities.each_slice(activities_per_layer).to_a

    # Connect start activity to first layer
    layers.first.each do |activity|
      program.add_predecessors(activity, [start_activity])
    end

    # Connect between layers
    layers.each_cons(2) do |current_layer, next_layer|
      next_layer.each do |activity|
        # Select 1 to MAX_PREDECESSORS predecessors from previous layer
        pred_count = rand(1...[MAX_PREDECESSORS, current_layer.size].min)
        predecessors = current_layer.sample(pred_count)
        program.add_predecessors(activity, predecessors)
      end
    end

    # Ensure all activities in the last layer connect to end activity
    program.add_predecessors(end_activity, layers.last)

    # Ensure all activities have at least one successor (except end activity)
    (layers.flatten).each do |activity|
      next_layer_activities = layers[layers.index { |l| l.include?(activity) } + 1]
      if next_layer_activities && !activity.successors.any?
        # If activity has no successors, connect it to a random activity in next layer
        successor = next_layer_activities.sample
        program.add_predecessors(successor, [activity])
      end
    end

    # Validate the program before returning
    program.validate
    if program.validation_errors.any?
      raise "Invalid program generated: #{program.validation_errors.join(', ')}"
    end

    program
  end

  describe "Large Scale Performance Comparison" do
    let(:program) { generate_large_program }
    let(:tmp_dir) { "tmp/diagrams" }
    let(:initial_diagram_path) { File.join(tmp_dir, "performance_test_network_initial.pdf") }
    let(:solved_diagram_path) { File.join(tmp_dir, "performance_test_network_solved.pdf") }

    before(:each) do
      FileUtils.mkdir_p(tmp_dir)

      # Generate initial network diagram
      puts "\nGenerating initial network diagram..."
      graph_builder = CpmSolver::Visualization::GraphBuilder.new(program)
      graph = graph_builder.build
      graph.output(pdf: initial_diagram_path)
      puts "Initial network diagram saved to: #{initial_diagram_path}"

      # Solve with Bellman-Ford and generate solved diagram
      puts "\nSolving with Bellman-Ford and generating solved diagram..."
      bellman_ford = CpmSolver::Solvers::BellmanFord.new(program)
      bellman_ford.solve

      solved_graph_builder = CpmSolver::Visualization::GraphBuilder.new(program)
      solved_graph = solved_graph_builder.build
      solved_graph.output(pdf: solved_diagram_path)
      puts "Solved network diagram saved to: #{solved_diagram_path}"

      summary_table = Terminal::Table.new do |t|
        t.title = "Test Configuration"
        t.headings = ['Parameter', 'Value']
        t.rows = [
          ['Activities', ACTIVITY_COUNT],
          ['Layers', LAYERS],
          ['Max predecessors', MAX_PREDECESSORS],
          ['Test iterations', ITERATIONS]
        ]
      end
      puts "\n#{summary_table}"

      network_table = Terminal::Table.new do |t|
        t.title = "Network Structure"
        t.headings = ['Network Property', 'Value']
        t.rows = [
          ['Start activity', program.start_activities.keys.first],
          ['End activity', program.end_activities.keys.first],
          ['Total activities', program.activities.size]
        ]
      end
      puts "\n#{network_table}"

      # Update network visualization table to include both diagrams
      diagram_table = Terminal::Table.new do |t|
        t.title = "Network Visualization"
        t.headings = ['Property', 'Value']
        t.rows = [
          ['Initial Diagram', initial_diagram_path],
          ['Solved Diagram', solved_diagram_path],
          ['Network Density', "#{program.activities.values.sum { |a| a.predecessors.size }} edges"],
          ['Critical Path Length', "#{program.critical_path_activities.size} activities"],
          ['Layout Algorithm', 'GraphViz dot'],
          ['Output Format', 'PDF']
        ]
      end
      puts "\n#{diagram_table}"
    end

    after(:each) do
      # Optionally clean up diagrams
      # [initial_diagram_path, solved_diagram_path].each do |path|
      #   File.delete(path) if File.exist?(path)
      # end
    end

    it "compares solver performance with large dataset" do
      results = {
        'Bellman-Ford' => [],
        'Floyd-Warshall' => [],
        'Topological' => [],
        'Dijkstra' => []
      }

      solvers = {
        'Bellman-Ford' => CpmSolver::Solvers::BellmanFord,
        'Floyd-Warshall' => CpmSolver::Solvers::FloydWarshall,
        'Topological' => CpmSolver::Solvers::Topological,
        'Dijkstra' => CpmSolver::Solvers::Dijkstra
      }

      # Run each solver multiple times
      solvers.each do |name, solver_class|
        puts "\nTesting #{name} solver..."
        iteration_rows = []

        ITERATIONS.times do |i|
          program_copy = Marshal.load(Marshal.dump(program))
          solver = solver_class.new(program_copy)

          start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          solver.solve
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          execution_time = end_time - start_time
          results[name] << execution_time
          iteration_rows << [i + 1, (execution_time * 1000).round(2)]
        end

        iteration_table = Terminal::Table.new do |t|
          t.title = "#{name} Solver Iterations"
          t.headings = ['Iteration', 'Time (ms)']
          t.rows = iteration_rows
        end
        puts iteration_table
      end

      # Display performance results
      performance_rows = results.map do |name, times|
        avg_time = (times.sum / times.length) * 1000
        min_time = times.min * 1000
        max_time = times.max * 1000

        [
          name,
          avg_time.round(2),
          min_time.round(2),
          max_time.round(2)
        ]
      end

      performance_table = Terminal::Table.new do |t|
        t.title = "Performance Results (#{ACTIVITY_COUNT} activities, #{ITERATIONS} iterations)"
        t.headings = ['Solver', 'Avg (ms)', 'Min (ms)', 'Max (ms)']
        t.rows = performance_rows
      end
      puts "\n#{performance_table}"

      # Comparison metrics
      baseline_solver = 'Bellman-Ford'
      baseline_avg = results[baseline_solver].sum / results[baseline_solver].length

      comparison_rows = results.each_with_object([]) do |(name, times), rows|
        next if name == baseline_solver
        avg_time = times.sum / times.length
        relative_speed = baseline_avg / avg_time
        speed_text = "#{relative_speed.round(2)}x #{relative_speed > 1 ? 'faster' : 'slower'}"
        rows << [name, speed_text]
      end

      comparison_table = Terminal::Table.new do |t|
        t.title = "Performance Comparison (relative to #{baseline_solver})"
        t.headings = ['Solver', 'Relative Speed']
        t.rows = comparison_rows
      end
      puts "\n#{comparison_table}"

      # Basic assertions
      results.each do |name, times|
        expect(times).not_to be_empty
        expect(times.all? { |t| t > 0 }).to be true
      end
    end
  end

  private

  def create_network_layers(activities)
    # Divide remaining activities into layers
    layer_count = Math.sqrt(activities.size).ceil
    activities_per_layer = (activities.size / layer_count.to_f).ceil

    activities.each_slice(activities_per_layer).to_a
  end
end
