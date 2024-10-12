require_relative "../spec_helper.rb"
require "cpm_solver/activity"

RSpec.describe CpmSolver::Activity do

  context "with valid data" do
    let(:activity) { CpmSolver::Activity.new("1020", "Site Preparation", 10) }
    let(:predecessor_activity_1) { CpmSolver::Activity.new("1000", "Early Works", 5) }
    let(:predecessor_activity_2) { CpmSolver::Activity.new("1010", "Site Office", 1) }

    it "should allow construction" do
      expect(activity.reference).to eq "1020"
      expect(activity.name).to eq "Site Preparation"
      expect(activity.duration).to eq 10
    end

    it "should store and return successors" do
      activity.add_predecessor(predecessor_activity_1)
      activity.add_predecessor(predecessor_activity_2)
      expect(activity.predecessors.count).to eq 2
    end
  end
end
