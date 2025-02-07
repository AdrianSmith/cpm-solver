module CpmSolver
  module Solvers
    class Dijkstra < Solver
      def calculate_early_times
        raise NotImplementedError, "#{self.class} must implement #calculate_early_times"
      end

      def calculate_late_times
        raise NotImplementedError, "#{self.class} must implement #calculate_late_times"
      end
    end
  end
end
