require "spec_helper"

RSpec.describe CpmSolver::Program do
  let(:program) { described_class.new("Test Program") }
  let(:activity1) { CpmSolver::Activity.new("A1", "Activity 1", 5) }
  let(:activity2) { CpmSolver::Activity.new("A2", "Activity 2", 3) }
  let(:activity3) { CpmSolver::Activity.new("A3", "Activity 3", 4) }

  describe "#validate" do
    context "when program is empty" do
      it "returns error for no activities" do
        program.validate
        expect(program.validation_errors).to include("No activities found")
        expect(program.status).to eq(CpmSolver::Program::STATUS[:invalid])
      end
    end

    context "when program has isolated activities" do
      before do
        program.add_activitity(activity1)
      end

      it "returns error for activities without connections" do
        program.validate
        expect(program.validation_errors).to include("Some activities have no predecessors or successors")
        expect(program.status).to eq(CpmSolver::Program::STATUS[:invalid])
      end
    end

    context "when program has multiple start activities" do
      before do
        program.add_activitity(activity1)
        program.add_activitity(activity2)
        program.add_activitity(activity3)
        program.add_predecessors(activity3, [ activity1, activity2 ])
      end

      it "returns error for multiple start activities" do
        program.validate
        expect(program.validation_errors).to include("More than one start activity found")
        expect(program.status).to eq(CpmSolver::Program::STATUS[:invalid])
      end
    end

    context "when program has multiple end activities" do
      before do
        program.add_activitity(activity1)
        program.add_activitity(activity2)
        program.add_activitity(activity3)
        program.add_predecessors(activity2, [ activity1 ])
        program.add_predecessors(activity3, [ activity1 ])
      end

      it "returns error for multiple end activities" do
        program.validate
        expect(program.validation_errors).to include("More than one end activity found")
        expect(program.status).to eq(CpmSolver::Program::STATUS[:invalid])
      end
    end

    context "when program has no start activities" do
      before do
        program.add_activitity(activity1)
        program.add_activitity(activity2)
        program.add_predecessors(activity1, [ activity2 ])
        program.add_predecessors(activity2, [ activity1 ])
      end

      it "returns error for no start activities" do
        program.validate
        expect(program.validation_errors).to include("No start activities found")
        expect(program.status).to eq(CpmSolver::Program::STATUS[:invalid])
      end
    end

    context "when program has no end activities" do
      before do
        program.add_activitity(activity1)
        program.add_activitity(activity2)
        program.add_predecessors(activity1, [ activity2 ])
        program.add_predecessors(activity2, [ activity1 ])
      end

      it "returns error for no end activities" do
        program.validate
        expect(program.validation_errors).to include("No end activities found")
        expect(program.status).to eq(CpmSolver::Program::STATUS[:invalid])
      end
    end

    context "when program is valid" do
      before do
        program.add_activitity(activity1)
        program.add_activitity(activity2)
        program.add_activitity(activity3)
        program.add_predecessors(activity2, [ activity1 ])
        program.add_predecessors(activity3, [ activity2 ])
      end

      it "returns no errors and sets status to validated" do
        program.validate
        expect(program.validation_errors).to be_empty
        expect(program.status).to eq(CpmSolver::Program::STATUS[:validated])
      end
    end
  end
end
