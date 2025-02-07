require "spec_helper"

RSpec.describe CpmSolver::IO::CsvReader do
  let(:test_data_dir) { File.join("spec", "test_data") }
  let(:csv_file) { File.join(test_data_dir, "house_100.csv") }
  let(:invalid_csv_file) { File.join(test_data_dir, "invalid_house.csv") }
  let(:reader) { described_class.new(csv_file) }

  before(:all) do
    # Create test data directory
    FileUtils.mkdir_p("spec/test_data")

    # Create invalid_house.csv for error testing
    File.write("spec/test_data/invalid_house.csv", <<~CSV)
      reference,name,duration,predecessors
      A,Foundation,5,
      B,Walls,4,A
      C,Roof,3,X
    CSV
  end

  after(:all) do
    # Only remove the invalid test file, keep house_100.csv
    File.delete("spec/test_data/invalid_house.csv") if File.exist?("spec/test_data/invalid_house.csv")
  end

  describe "#read" do
    let(:activities) { reader.read }

    it "reads activities from CSV file" do
      expect(activities).not_to be_empty
    end

    it "creates activities with correct attributes" do
      first_activity = activities.values.first
      expect(first_activity).to be_a(CpmSolver::Core::Activity)
      expect(first_activity.reference).not_to be_nil
      expect(first_activity.name).not_to be_nil
      expect(first_activity.duration).to be_a(Integer)
    end

    it "links predecessors correctly" do
      activities_with_predecessors = activities.values.select { |a| a.predecessors.any? }
      expect(activities_with_predecessors).not_to be_empty
    end

    context "when predecessor not found" do
      let(:reader) { described_class.new(invalid_csv_file) }

      it "raises an error" do
        expect { activities }.to raise_error(RuntimeError, /Predecessor X not found/)
      end
    end
  end
end
