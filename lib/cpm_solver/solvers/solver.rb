module CpmSolver
  module Solvers
    # Base class defining the interface for all CPM solvers
    class Solver
      def initialize(program)
        @program = program
      end

      def solve
        validate_program
        calculate_early_times
        calculate_late_times
        calculate_slack
      end

      protected

      attr_reader :program

      # Calculate early start and finish times for all activities
      # Must be implemented by concrete solvers
      def calculate_early_times
        raise NotImplementedError, "#{self.class} must implement #calculate_early_times"
      end

      # Calculate late start and finish times for all activities
      # Must be implemented by concrete solvers
      def calculate_late_times
        raise NotImplementedError, "#{self.class} must implement #calculate_late_times"
      end

      # Calculate slack for all activities
      def calculate_slack
        program.activities.each_value(&:slack)
      end

      private

      def validate_program
        program.validate
        unless program.status == CpmSolver::Core::Program::STATUS[:validated]
          raise "Program must be valid before solving. Errors: #{program.validation_errors.join(', ')}"
        end
      end
    end
  end
end
