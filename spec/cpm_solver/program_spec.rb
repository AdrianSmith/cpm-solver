require_relative "../spec_helper.rb"
require "cpm_solver/program"

RSpec.describe CpmSolver::Program do

  context "with valid data" do
    # https://www.pmcalculators.com/how-to-calculate-the-critical-path/
    let(:program) { CpmSolver::Program.new("Test") }
    let(:start_date) { Date.new(2020, 3, 1) }
    let(:activity_Start) { CpmSolver::Activity.new("Start", "Start", 0) }
    let(:activity_A) { CpmSolver::Activity.new("A", "A", 3) }
    let(:activity_B) { CpmSolver::Activity.new("B", "B", 4) }
    let(:activity_C) { CpmSolver::Activity.new("C", "C", 6) }
    let(:activity_D) { CpmSolver::Activity.new("D", "D", 6) }
    let(:activity_E) { CpmSolver::Activity.new("E", "E", 4) }
    let(:activity_F) { CpmSolver::Activity.new("F", "F", 4) }
    let(:activity_G) { CpmSolver::Activity.new("G", "G", 6) }
    let(:activity_H) { CpmSolver::Activity.new("H", "H", 8) }
    let(:activity_End) { CpmSolver::Activity.new("End", "End", 0) }

    before do
      activity_Start.planned_start = start_date
      program.add_activitity(activity_Start)
      program.add_activitity(activity_A)
      program.add_activitity(activity_B)
      program.add_activitity(activity_C)
      program.add_activitity(activity_D)
      program.add_activitity(activity_E)
      program.add_activitity(activity_F)
      program.add_activitity(activity_G)
      program.add_activitity(activity_H)
      program.add_activitity(activity_End)

      program.add_predecessors(activity_A, [activity_Start])
      program.add_predecessors(activity_B, [activity_A])
      program.add_predecessors(activity_C, [activity_A])
      program.add_predecessors(activity_D, [activity_B])
      program.add_predecessors(activity_E, [activity_B])
      program.add_predecessors(activity_F, [activity_C])
      program.add_predecessors(activity_G, [activity_D])
      program.add_predecessors(activity_H, [activity_E, activity_F])
      program.add_predecessors(activity_End, [activity_H, activity_G])
    end

    it "should allow program creation from activities" do
      expect(program.name).to eq "Test"
      expect(program.activities.count).to eq 10
    end

    it "should display summary" do
      expect(program.to_s).to_not eq ""
    end

    it "should generate a directed diagram as pdf file" do
      program.to_pdf
      expect(File.exist?("Test.pdf")).to be true
    end

    context "with program start dates" do
      context "after a forward pass" do
        before do
          program.forward_pass
        end

        it "should calculate early dates using predecessors" do
          expect(activity_A.early_start).to eq start_date
          expect(activity_A.early_finish).to eq start_date + activity_A.duration
        end

        it "should calculate early dates for concurrent predecessors" do
          expect(activity_B.early_start).to eq activity_A.early_finish
          expect(activity_B.early_finish).to eq activity_A.early_finish + activity_B.duration

          expect(activity_C.early_start).to eq activity_A.early_finish
          expect(activity_C.early_finish).to eq activity_A.early_finish + activity_C.duration

          expect(activity_H.early_start).to eq activity_F.early_finish
          expect(activity_H.early_finish).to eq activity_F.early_finish + activity_H.duration
        end

        context "after a backwards pass" do
          before do
            program.backward_pass
          end

          it "should calculate late dates" do
            expect(activity_End.late_finish).to eq activity_End.early_finish
            expect(activity_End.late_start).to eq activity_End.late_finish - activity_End.duration

            expect(activity_E.late_start).to eq start_date + 9
            expect(activity_E.late_finish).to eq start_date + 13

            expect(activity_C.late_start).to eq start_date + 3
            expect(activity_C.late_finish).to eq start_date + 9
          end

          context "after calculation of slack" do
            it "should identify critical path activities" do
              expect(program.critical_path_activities.count).to eq 6
              expect(activity_A.critical).to be true
              expect(activity_B.critical).to be false
              expect(activity_C.critical).to be true
              expect(activity_D.critical).to be false
              expect(activity_E.critical).to be false
              expect(activity_F.critical).to be true
              expect(activity_G.critical).to be false
              expect(activity_H.critical).to be true
            end
          end
        end
      end
    end
  end

  def create_house_schedule
    # Source: https://hbr.org/1963/09/the-abcs-of-the-critical-path-method
    let(:activity_a) { CpmSolver::Activity.new("a", "Start", 0) }
    let(:activity_b) { CpmSolver::Activity.new("b", "Excavate and pour footers", 4, [activity_a]) }
    let(:activity_c) { CpmSolver::Activity.new("c", "Pour concrete foundation", 2, [activity_b]) }
    let(:activity_d) { CpmSolver::Activity.new("d", "Erect wooden frame including rough roof", 4, [activity_c]) }
    let(:activity_e) { CpmSolver::Activity.new("e", "Lay brickwork", 6, [activity_d]) }
    let(:activity_f) { CpmSolver::Activity.new("f", "Install basement drains and plumbing", 1, [activity_c]) }
    let(:activity_g) { CpmSolver::Activity.new("f", "Pour basement floor", 2, [activity_f]) }
    let(:activity_h) { CpmSolver::Activity.new("h", "Install rough plumbing", 3, [activity_f]) }
    let(:activity_i) { CpmSolver::Activity.new("i", "Install rough wiring", 2, [activity_d]) }
    let(:activity_j) { CpmSolver::Activity.new("j", "Install heating and ventilating", 4, [activity_d, activity_g]) }
    let(:activity_k) { CpmSolver::Activity.new("k", "Fasten plaster board and plaster (including drying)", 10, [activity_i, activity_j, activity_h]) }
    let(:activity_l) { CpmSolver::Activity.new("l", "Lay finish flooring", 3, [activity_k]) }
    let(:activity_m) { CpmSolver::Activity.new("m", "Install kitchen fixtures", 1, [activity_l]) }
    let(:activity_n) { CpmSolver::Activity.new("n", "Install finish plumbing", 2, [activity_l]) }
    let(:activity_o) { CpmSolver::Activity.new("o", "Finish carpentry", 3, [activity_l]) }
    let(:activity_p) { CpmSolver::Activity.new("p", "Finish roofing and flashing", 2, [activity_o]) }
    let(:activity_q) { CpmSolver::Activity.new("q", "Fasten gutters and downspouts", 1, [activity_p]) }
    let(:activity_r) { CpmSolver::Activity.new("r", "Lay storm drains for rain water", 1, [activity_c]) }
    let(:activity_s) { CpmSolver::Activity.new("s", "Sand and varnish flooring", 2, [activity_o, activity_t]) }
    let(:activity_t) { CpmSolver::Activity.new("t", "Paint", 3, [activity_m, activity_n]) }
    let(:activity_u) { CpmSolver::Activity.new("u", "Finish electrical work", 1, [activity_t]) }
    let(:activity_v) { CpmSolver::Activity.new("v", "Finish grading", 2, [activity_q, activity_r]) }
    let(:activity_w) { CpmSolver::Activity.new("w", "Pour walks and complete landscaping", 5, [activity_v]) }
    let(:activity_x) { CpmSolver::Activity.new("x", "Finish", 0, [activity_s, activity_u, activity_w]) }

    let(:activities) do
      [
        activity_a,
        activity_b,
        activity_c,
        activity_d,
        activity_e,
        activity_f,
        activity_g,
        activity_h,
        activity_i,
        activity_j,
        activity_k,
        activity_l,
        activity_m,
        activity_n,
        activity_o,
        activity_p,
        activity_q,
        activity_r,
        activity_s,
        activity_t,
        activity_u,
        activity_v,
        activity_w,
        activity_x,
      ]
    end

    let(:program) { CpmSolver::Program.new("Schedule", activities) }
  end
end
