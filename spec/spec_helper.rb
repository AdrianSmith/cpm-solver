require "cpm_solver"
require "cpm_solver/solvers/critical_path"
require "cpm_solver/solvers/bellman_ford"
require "cpm_solver/solvers/floyd_warshall"
require "cpm_solver/solvers/topological"
require "cpm_solver/solvers/dijkstra"
require "pry"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Exclude integration and performance tests by default
  config.filter_run_excluding integration: true, performance: true
end
