require "spec_helper"

RSpec.describe CpmSolver::Solvers::Solver do
  let(:program) { instance_double("CpmSolver::Core::Program") }
  let(:solver) { described_class.new(program) }

  describe "#solve" do
    before do
      # Set up expectations for validate and status
      allow(program).to receive(:validate)
      allow(program).to receive(:status).and_return(CpmSolver::Core::Program::STATUS[:validated])
      allow(program).to receive(:validation_errors).and_return([])
    end

    it "calls the required methods in order" do
      expect(program).to receive(:validate).ordered
      expect(solver).to receive(:calculate_early_times).ordered
      expect(solver).to receive(:calculate_late_times).ordered
      expect(solver).to receive(:calculate_slack).ordered

      solver.solve
    end
  end

  describe "#calculate_early_times" do
    it "raises NotImplementedError" do
      expect { solver.send(:calculate_early_times) }.to raise_error(NotImplementedError)
    end
  end

  describe "#calculate_late_times" do
    it "raises NotImplementedError" do
      expect { solver.send(:calculate_late_times) }.to raise_error(NotImplementedError)
    end
  end
end
