require "spec_helper"

RSpec.describe CpmSolver::Solvers::CriticalPath do
  let(:program) { CpmSolver::Core::Program.new("Test Program") }
  let(:solver) { described_class.new(program) }
  let(:activity_a) { CpmSolver::Core::Activity.new("A", "Task A", 5) }
  let(:activity_b) { CpmSolver::Core::Activity.new("B", "Task B", 3) }
  let(:activity_c) { CpmSolver::Core::Activity.new("C", "Task C", 4) }

  before do
    program.add_activity(activity_a)
    program.add_activity(activity_b)
    program.add_activity(activity_c)
    program.add_predecessors(activity_b, [activity_a])
    program.add_predecessors(activity_c, [activity_a, activity_b])
  end

  describe "#calculate_early_times" do
    before { solver.send(:calculate_early_times) }

    it "calculates early start times" do
      expect(activity_a.early_start).to eq(0)
      expect(activity_b.early_start).to eq(5)
      expect(activity_c.early_start).to eq(8)
    end

    it "calculates early finish times" do
      expect(activity_a.early_finish).to eq(5)
      expect(activity_b.early_finish).to eq(8)
      expect(activity_c.early_finish).to eq(12)
    end
  end

  describe "#calculate_late_times" do
    before do
      solver.send(:calculate_early_times)
      solver.send(:calculate_late_times)
    end

    it "calculates late start times" do
      expect(activity_a.late_start).to eq(0)
      expect(activity_b.late_start).to eq(5)
      expect(activity_c.late_start).to eq(8)
    end

    it "calculates late finish times" do
      expect(activity_a.late_finish).to eq(5)
      expect(activity_b.late_finish).to eq(8)
      expect(activity_c.late_finish).to eq(12)
    end
  end

  describe "#solve" do
    before { solver.solve }

    it "calculates slack times" do
      expect(activity_a.slack).to eq(0)
      expect(activity_b.slack).to eq(0)
      expect(activity_c.slack).to eq(0)
    end

    it "identifies critical path" do
      expect(activity_a.critical).to be true
      expect(activity_b.critical).to be true
      expect(activity_c.critical).to be true
    end
  end
end
