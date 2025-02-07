require "spec_helper"
require "cpm_solver/solvers/topological"

RSpec.describe CpmSolver::Solvers::Topological do
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
    program.add_predecessors(activity_c, [activity_b])
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

  context "with parallel paths" do
    let(:activity_d) { CpmSolver::Core::Activity.new("D", "Task D", 2) }
    let(:activity_e) { CpmSolver::Core::Activity.new("E", "Task E", 3) }

    before do
      program.add_activity(activity_d)
      program.add_activity(activity_e)
      program.add_predecessors(activity_d, [activity_a])
      program.add_predecessors(activity_e, [activity_d])
      program.add_predecessors(activity_c, [activity_b, activity_e])
    end

    it "calculates correct early and late times for parallel paths" do
      solver.solve

      # Verify early times
      expect(activity_a.early_start).to eq(0)
      expect(activity_b.early_start).to eq(5)
      expect(activity_d.early_start).to eq(5)
      expect(activity_d.early_finish).to eq(7)
      expect(activity_e.early_start).to eq(7)
      expect(activity_e.early_finish).to eq(10)
      expect(activity_c.early_start).to eq(10) # Must wait for both B and E

      # In this case, both paths are critical because:
      # Path 1: A -> B -> C (5 + 3 + 4 = 12)
      # Path 2: A -> D -> E -> C (5 + 2 + 3 + 4 = 14)
      # Path 2 is actually longer, making it the critical path
      expect(activity_d.critical).to be true
      expect(activity_e.critical).to be true
      expect(activity_b.slack).to be > 0  # B has slack because it's not on the critical path
    end
  end
end
