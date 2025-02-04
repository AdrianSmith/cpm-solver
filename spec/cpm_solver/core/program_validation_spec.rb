require "spec_helper"

RSpec.describe CpmSolver::Core::Program do
  let(:program) { described_class.new("Test Program") }
  let(:activity_a) { CpmSolver::Core::Activity.new("A", "Task A", 5) }
  let(:activity_b) { CpmSolver::Core::Activity.new("B", "Task B", 3) }
  let(:activity_c) { CpmSolver::Core::Activity.new("C", "Task C", 4) }

  describe "#validate" do
    context "when program has no activities" do
      it "returns validation error" do
        program.validate
        expect(program.validation_errors).to include("No activities found")
        expect(program.status).to eq(CpmSolver::Core::Program::STATUS[:invalid])
      end
    end

    context "when program has no start activities" do
      before do
        program.add_activity(activity_a)
        program.add_activity(activity_b)
        program.add_predecessors(activity_a, [activity_b])
        program.add_predecessors(activity_b, [activity_a])
      end

      it "returns validation error" do
        program.validate
        expect(program.validation_errors).to include("No start activities found")
        expect(program.status).to eq(CpmSolver::Core::Program::STATUS[:invalid])
      end
    end

    context "when program has multiple start activities" do
      before do
        program.add_activity(activity_a)
        program.add_activity(activity_b)
        program.add_activity(activity_c)
        program.add_predecessors(activity_c, [activity_a])
      end

      it "returns validation error" do
        program.validate
        expect(program.validation_errors).to include("More than one start activity found")
        expect(program.status).to eq(CpmSolver::Core::Program::STATUS[:invalid])
      end
    end

    context "when program has no end activities" do
      before do
        program.add_activity(activity_a)
        program.add_activity(activity_b)
        program.add_predecessors(activity_a, [activity_b])
        program.add_predecessors(activity_b, [activity_a])
      end

      it "returns validation error" do
        program.validate
        expect(program.validation_errors).to include("No end activities found")
        expect(program.status).to eq(CpmSolver::Core::Program::STATUS[:invalid])
      end
    end

    context "when program has multiple end activities" do
      before do
        program.add_activity(activity_a)
        program.add_activity(activity_b)
        program.add_activity(activity_c)
        program.add_predecessors(activity_b, [activity_a])
      end

      it "returns validation error" do
        program.validate
        expect(program.validation_errors).to include("More than one end activity found")
        expect(program.status).to eq(CpmSolver::Core::Program::STATUS[:invalid])
      end
    end

    context "when program has isolated activities" do
      before do
        program.add_activity(activity_a)
        program.add_activity(activity_b)
        program.add_activity(activity_c)
        program.add_predecessors(activity_c, [activity_a])
      end

      it "returns validation error" do
        program.validate
        expect(program.validation_errors).to include("Some activities have no predecessors or successors")
        expect(program.status).to eq(CpmSolver::Core::Program::STATUS[:invalid])
      end
    end

    context "when program is valid" do
      before do
        program.add_activity(activity_a)
        program.add_activity(activity_b)
        program.add_activity(activity_c)
        program.add_predecessors(activity_b, [activity_a])
        program.add_predecessors(activity_c, [activity_b])
      end

      it "returns no validation errors" do
        program.validate
        expect(program.validation_errors).to be_empty
        expect(program.status).to eq(CpmSolver::Core::Program::STATUS[:validated])
      end
    end
  end
end
