# frozen_string_literal: true

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
      puts program.end_activities
      expect(program.end_activities.size).to eq(1)
    end

    it "calculates the correct critical path"
  end
end
