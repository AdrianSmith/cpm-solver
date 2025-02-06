require "spec_helper"

RSpec.describe "Solver Performance Tests" do
  # Define as constants instead of let
  ITERATIONS = 5
  ACTIVITY_COUNT = 200
  MAX_PREDECESSORS = 5
  LAYERS = 10  # Define number of layers for better control

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

  private

  def create_network_layers(activities)
    # Divide remaining activities into layers
    layer_count = Math.sqrt(activities.size).ceil
    activities_per_layer = (activities.size / layer_count.to_f).ceil

    activities.each_slice(activities_per_layer).to_a
  end

  describe "Large Scale Performance Comparison" do
    let(:program) { generate_large_program }

    before(:each) do
      puts "\nGenerating performance test data..."
      puts "Activities: #{ACTIVITY_COUNT}"
      puts "Layers: #{LAYERS}"
      puts "Max predecessors per activity: #{MAX_PREDECESSORS}"
      puts "Test iterations: #{ITERATIONS}"

      # Print network statistics
      puts "\nNetwork structure:"
      puts "Start activity: #{program.start_activities.keys.first}"
      puts "End activity: #{program.end_activities.keys.first}"
      puts "Total activities: #{program.activities.size}"
    end

    it "compares solver performance with large dataset" do
      results = {
        'Bellman-Ford' => [],
        'Floyd-Warshall' => []
      }

      solvers = {
        'Bellman-Ford' => CpmSolver::Solvers::BellmanFord,
        'Floyd-Warshall' => CpmSolver::Solvers::FloydWarshall
      }

      # Run each solver multiple times
      solvers.each do |name, solver_class|
        puts "\nTesting #{name} solver..."

        ITERATIONS.times do |i|
          print "  Iteration #{i + 1}/#{ITERATIONS}..."

          program_copy = Marshal.load(Marshal.dump(program))
          solver = solver_class.new(program_copy)

          start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          solver.solve
          end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

          execution_time = end_time - start_time
          results[name] << execution_time
          puts " #{(execution_time * 1000).round(2)}ms"
        end
      end

      # Display results
      puts "\nPerformance Results (#{ACTIVITY_COUNT} activities, #{ITERATIONS} iterations):"
      puts "-" * 65
      puts "| #{'Solver'.ljust(15)} | #{'Avg (ms)'.ljust(12)} | #{'Min (ms)'.ljust(12)} | #{'Max (ms)'.ljust(12)} |"
      puts "-" * 65

      results.each do |name, times|
        avg_time = (times.sum / times.length) * 1000
        min_time = times.min * 1000
        max_time = times.max * 1000

        puts "| #{name.ljust(15)} | #{avg_time.round(2).to_s.ljust(12)} | #{min_time.round(2).to_s.ljust(12)} | #{max_time.round(2).to_s.ljust(12)} |"
      end
      puts "-" * 65

      # Basic assertions
      results.each do |name, times|
        expect(times).not_to be_empty
        expect(times.all? { |t| t > 0 }).to be true
      end
    end
  end
end
