require_relative "../spec_helper.rb"
require "cpm_solver/program"

RSpec.describe CpmSolver::Program do

  context "with simple program data" do
    # https://www.pmcalculators.com/how-to-calculate-the-critical-path/
    let(:program) { CpmSolver::Program.new("Test") }
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
          expect(activity_A.early_start).to eq 0
          expect(activity_A.early_finish).to eq activity_A.duration
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

            expect(activity_E.late_start).to eq 9
            expect(activity_E.late_finish).to eq 13

            expect(activity_C.late_start).to eq 3
            expect(activity_C.late_finish).to eq 9
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

  context "with house program data" do
    # Source: https://hbr.org/1963/09/the-abcs-of-the-critical-path-method
    let(:program) { CpmSolver::Program.new("HBR Program") }
    let(:start_date) { Date.new(2020, 3, 1) }
    let(:activity_a) { CpmSolver::Activity.new("a", "Start", 0) }
    let(:activity_b) { CpmSolver::Activity.new("b", "Excavate and pour footers", 4) }
    let(:activity_c) { CpmSolver::Activity.new("c", "Pour concrete foundation", 2) }
    let(:activity_d) { CpmSolver::Activity.new("d", "Erect wooden frame including rough roof", 4) }
    let(:activity_e) { CpmSolver::Activity.new("e", "Lay brickwork", 6) }
    let(:activity_f) { CpmSolver::Activity.new("f", "Install basement drains and plumbing", 1) }
    let(:activity_g) { CpmSolver::Activity.new("g", "Pour basement floor", 2) }
    let(:activity_h) { CpmSolver::Activity.new("h", "Install rough plumbing", 3) }
    let(:activity_i) { CpmSolver::Activity.new("i", "Install rough wiring", 2) }
    let(:activity_j) { CpmSolver::Activity.new("j", "Install heating and ventilating", 4) }
    let(:activity_k) { CpmSolver::Activity.new("k", "Fasten plaster board and plaster (including drying)", 10) }
    let(:activity_l) { CpmSolver::Activity.new("l", "Lay finish flooring", 3) }
    let(:activity_m) { CpmSolver::Activity.new("m", "Install kitchen fixtures", 1) }
    let(:activity_n) { CpmSolver::Activity.new("n", "Install finish plumbing", 2) }
    let(:activity_o) { CpmSolver::Activity.new("o", "Finish carpentry", 3) }
    let(:activity_p) { CpmSolver::Activity.new("p", "Finish roofing and flashing", 2) }
    let(:activity_q) { CpmSolver::Activity.new("q", "Fasten gutters and downspouts", 1) }
    let(:activity_r) { CpmSolver::Activity.new("r", "Lay storm drains for rain water", 1) }
    let(:activity_s) { CpmSolver::Activity.new("s", "Sand and varnish flooring", 2) }
    let(:activity_t) { CpmSolver::Activity.new("t", "Paint", 3) }
    let(:activity_u) { CpmSolver::Activity.new("u", "Finish electrical work", 1) }
    let(:activity_v) { CpmSolver::Activity.new("v", "Finish grading", 2) }
    let(:activity_w) { CpmSolver::Activity.new("w", "Pour walks and complete landscaping", 5) }
    let(:activity_x) { CpmSolver::Activity.new("x", "Finish", 0) }

    before do
      program.add_activitity(activity_a)
      program.add_activitity(activity_b)
      program.add_activitity(activity_c)
      program.add_activitity(activity_d)
      program.add_activitity(activity_e)
      program.add_activitity(activity_f)
      program.add_activitity(activity_g)
      program.add_activitity(activity_h)
      program.add_activitity(activity_i)
      program.add_activitity(activity_j)
      program.add_activitity(activity_k)
      program.add_activitity(activity_l)
      program.add_activitity(activity_m)
      program.add_activitity(activity_n)
      program.add_activitity(activity_o)
      program.add_activitity(activity_p)
      program.add_activitity(activity_q)
      program.add_activitity(activity_r)
      program.add_activitity(activity_s)
      program.add_activitity(activity_t)
      program.add_activitity(activity_u)
      program.add_activitity(activity_v)
      program.add_activitity(activity_w)
      program.add_activitity(activity_x)

      program.add_predecessors(activity_b, [activity_a])
      program.add_predecessors(activity_c, [activity_b])
      program.add_predecessors(activity_d, [activity_c])
      program.add_predecessors(activity_e, [activity_d])
      program.add_predecessors(activity_f, [activity_c])
      program.add_predecessors(activity_g, [activity_f])
      program.add_predecessors(activity_h, [activity_f])
      program.add_predecessors(activity_i, [activity_d])
      program.add_predecessors(activity_j, [activity_d, activity_g])
      program.add_predecessors(activity_k, [activity_i, activity_j, activity_h])
      program.add_predecessors(activity_l, [activity_k])
      program.add_predecessors(activity_m, [activity_l])
      program.add_predecessors(activity_n, [activity_l])
      program.add_predecessors(activity_o, [activity_l])
      program.add_predecessors(activity_p, [activity_o])
      program.add_predecessors(activity_q, [activity_p])
      program.add_predecessors(activity_r, [activity_c])
      program.add_predecessors(activity_s, [activity_o, activity_t])
      program.add_predecessors(activity_t, [activity_m, activity_n])
      program.add_predecessors(activity_u, [activity_t])
      program.add_predecessors(activity_v, [activity_q, activity_r])
      program.add_predecessors(activity_w, [activity_v])
      program.add_predecessors(activity_x, [activity_s, activity_u, activity_w])

      program.critical_path_activities
    end

    it "should display summary" do
      puts program.to_s
      expect(program.to_s).to_not eq ""
    end

    it "should generate a directed diagram as pdf file" do
      program.to_pdf
      expect(File.exist?("HBR Program.pdf")).to be true
    end
  end
end
