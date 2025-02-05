require "spec_helper"

RSpec.describe CpmSolver::Solvers::Dijkstra do
  let(:program) { instance_double(CpmSolver::Core::Program) }

  describe '#solve' do
    subject(:solver) { described_class.new(program) }

    before do
      allow(program).to receive(:validate)
      allow(program).to receive(:status).and_return(CpmSolver::Core::Program::STATUS[:validated])
      allow(program).to receive(:activities).and_return({})
    end

    it 'raises NotImplementedError when calculating early times' do
      expect { solver.solve }.to raise_error(
        NotImplementedError,
        "CpmSolver::Solvers::Dijkstra must implement #calculate_early_times"
      )
    end
  end
end
