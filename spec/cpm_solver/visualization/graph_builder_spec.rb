require "spec_helper"
require "cpm_solver/visualization/graph_builder"
require "cpm_solver/core/program"
require "cpm_solver/core/activity"

RSpec.describe CpmSolver::Visualization::GraphBuilder do
  let(:program) { CpmSolver::Core::Program.new("Test Program") }
  let(:activity_a) { CpmSolver::Core::Activity.new("A", "Task A", 5) }
  let(:activity_b) { CpmSolver::Core::Activity.new("B", "Task B", 3) }
  let(:activity_c) { CpmSolver::Core::Activity.new("C", "Task C", 4) }
  let(:activity_d) { CpmSolver::Core::Activity.new("D", "Task D", 2) }

  before do
    program.add_activity(activity_a)
    program.add_activity(activity_b)
    program.add_activity(activity_c)
    program.add_activity(activity_d)

    # Set up activity relationships
    program.add_predecessors(activity_b, [activity_a])
    program.add_predecessors(activity_c, [activity_a])
    program.add_predecessors(activity_d, [activity_b, activity_c])

    # Calculate critical path to set ES, EF, LS, LF values
    program.solve
  end

  describe "#build" do
    let(:graph_builder) { described_class.new(program) }
    let(:graph) { graph_builder.build }

    it "creates a directed graph" do
      expect(graph.type).to eq("digraph")
    end

    it "creates nodes for all activities" do
      expect(graph.node_count).to eq(4)
    end

    it "creates edges between activities based on predecessors" do
      expect(graph.edge_count).to eq(4) # A->B and A->C and C->D and B->D
    end

    it "includes activity details in node labels" do
      node_a = graph.get_node(activity_a.to_s)
      label = node_a[:label].to_s

      expect(label).to include("ES: 0")
      expect(label).to include("D: 5")
      expect(label).to include("EF: 5")
      expect(label).to include("LS: 0")
      expect(label).to include("S: 0")
      expect(label).to include("LF: 5")
      expect(label).to include("A")
      expect(label).to include("Task A")
    end
  end
end
