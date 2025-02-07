require "spec_helper"

RSpec.describe CpmSolver::Core::Activity do
  let(:activity) { described_class.new("A", "Task A", 5) }
  let(:predecessor) { described_class.new("B", "Task B", 3) }
  let(:successor) { described_class.new("C", "Task C", 4) }

  describe "#add_predecessor" do
    it "adds a predecessor reference" do
      activity.add_predecessor(predecessor)
      expect(activity.predecessors).to include(predecessor.reference)
    end
  end

  describe "#add_successor" do
    it "adds a successor reference" do
      activity.add_successor(successor)
      expect(activity.successors).to include(successor.reference)
    end
  end

  describe "#to_s" do
    it "returns a string representation" do
      expect(activity.to_s).to eq("A - Task A")
    end
  end
end
