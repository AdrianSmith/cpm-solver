require "spec_helper"

RSpec.describe CpmSolver::IO::CsvReader do
  let(:csv_file) { File.join(__dir__, "../../fixtures/activities.csv") }
  let(:reader) { described_class.new(csv_file) }

  describe "#read" do
    subject(:activities) { reader.read }

    it "reads activities from CSV file" do
      expect(activities).to be_a(Hash)
      expect(activities.size).to eq(3)
    end

    it "creates activities with correct attributes" do
      activity = activities["A"]
      expect(activity).to be_a(CpmSolver::Core::Activity)
      expect(activity.reference).to eq("A")
      expect(activity.name).to eq("Task A")
      expect(activity.duration).to eq(5)
    end

    it "links predecessors correctly" do
      activity_c = activities["C"]
      expect(activity_c.predecessors).to contain_exactly("A", "B")
    end

    it "links successors correctly" do
      activity_a = activities["A"]
      expect(activity_a.successors).to contain_exactly("C")
    end

    context "when predecessor not found" do
      let(:csv_file) { File.join(__dir__, "../../fixtures/invalid_activities.csv") }

      it "raises an error" do
        expect { activities }.to raise_error(RuntimeError, /Predecessor .* not found/)
      end
    end
  end
end
