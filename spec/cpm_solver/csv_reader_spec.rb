require "spec_helper"
require "cpm_solver/csv_reader"

RSpec.describe CpmSolver::CsvReader do
  describe ".read" do
    let(:file_path) { File.join(__dir__, "../test_data/house_100.csv") }
    let(:program) { described_class.read(file_path) }

    before do
      program.solve
    end

    it "should generate a directed diagram as pdf file" do
      program.dependency_diagram
      expect(File.exist?("house_100.pdf")).to be true
    end

    it "should have 1 start activity" do
      expect(program.start_activities.size).to eq(1)
    end

    it "should have 1 end activity" do
      expect(program.end_activities.size).to eq(1)
    end

    it "calculates the correct critical path" do
      expected_critical = %w[
        1 2 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20
        21 22 23 37 38 39 46 47 48 49 50 51 52 54 55 56 59 61 82 92 99 100
      ]
      actual_critical = program.critical_path_activities.keys
      expect(actual_critical).to eq(expected_critical)
    end
  end
end
