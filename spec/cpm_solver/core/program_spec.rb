require "spec_helper"
require "fileutils"

RSpec.describe CpmSolver::Core::Program do
  let(:tmp_dir) { "tmp/diagrams" }
  let(:keep_pdfs) { ENV['KEEP_PDFS'] == 'true' }
  let(:program) { described_class.new("Test") }
  let(:activity_A) { CpmSolver::Core::Activity.new("A", "Task A", 3) }
  let(:activity_B) { CpmSolver::Core::Activity.new("B", "Task B", 4) }
  let(:activity_C) { CpmSolver::Core::Activity.new("C", "Task C", 6) }
  let(:activity_D) { CpmSolver::Core::Activity.new("D", "Task D", 5) }
  let(:activity_E) { CpmSolver::Core::Activity.new("E", "Task E", 4) }
  let(:activity_F) { CpmSolver::Core::Activity.new("F", "Task F", 3) }
  let(:activity_G) { CpmSolver::Core::Activity.new("G", "Task G", 8) }
  let(:activity_H) { CpmSolver::Core::Activity.new("H", "Task H", 8) }
  let(:activity_End) { CpmSolver::Core::Activity.new("End", "End", 0) }

  before do
    FileUtils.mkdir_p(tmp_dir)
  end

  after do
    unless keep_pdfs
      Dir.glob(File.join(tmp_dir, "*.pdf")).each do |file|
        File.delete(file) if File.exist?(file)
      end
      FileUtils.rm_r(tmp_dir) if Dir.empty?(tmp_dir)
      FileUtils.rm_r("tmp") if Dir.exist?("tmp") && Dir.empty?("tmp")
    end
  end

  it "should allow program creation from activities" do
    [activity_A, activity_B, activity_C, activity_D, activity_E, activity_F, activity_G, activity_H].each do |activity|
      program.add_activity(activity)
    end
    expect(program.activities.count).to eq 8
  end

  it "should display summary" do
    expect(program.to_s).to_not eq ""
  end

  context "after solving" do
    before do
      # Basic test setup with single start and end
      program.add_activity(activity_A)
      program.add_activity(activity_B)
      program.add_activity(activity_C)
      program.add_activity(activity_H)
      program.add_activity(activity_E)
      program.add_activity(activity_End)

      # Set up dependencies
      program.add_predecessors(activity_B, [activity_A])
      program.add_predecessors(activity_C, [activity_A])
      program.add_predecessors(activity_H, [activity_B, activity_C])
      program.add_predecessors(activity_E, [activity_C])
      program.add_predecessors(activity_End, [activity_H, activity_E])

      program.validate
      expect(program.validation_errors).to be_empty
      program.solve
    end

    it "should generate a directed diagram as pdf file" do
      program.dependency_diagram
      expect(File.exist?(File.join(tmp_dir, "#{program.name}.pdf"))).to be true
    end

    it "should calculate early dates using predecessors" do
      expect(activity_A.early_start).to eq 0
      expect(activity_A.early_finish).to eq 3
    end

    it "should calculate early dates for concurrent predecessors" do
      expect(activity_B.early_start).to eq 3
      expect(activity_B.early_finish).to eq 7

      expect(activity_C.early_start).to eq 3
      expect(activity_C.early_finish).to eq 9

      expect(activity_H.early_start).to eq 9
      expect(activity_H.early_finish).to eq 17
    end

    it "should calculate late dates" do
      expect(activity_End.late_finish).to eq activity_End.early_finish
      expect(activity_End.late_start).to eq activity_End.late_finish - activity_End.duration

      expect(activity_E.late_start).to eq 13
      expect(activity_E.late_finish).to eq 17
    end

    it "should identify critical path activities" do
      critical_activities = program.critical_path_activities
      expect(critical_activities).not_to be_empty
    end
  end

  context "with production process data" do
    # Source: https://hbr.org/1963/09/the-abcs-of-the-critical-path-method
    let(:program) { CpmSolver::Core::Program.new("HBR Production Process") }
    let(:start_date) { Date.new(2020, 3, 1) }
    let(:activity_a) { CpmSolver::Core::Activity.new("a", "Start", 0) }
    let(:activity_b) { CpmSolver::Core::Activity.new("b", "Get materials for A", 10) }
    let(:activity_c) { CpmSolver::Core::Activity.new("c", "Get materials for B", 20) }
    let(:activity_d) { CpmSolver::Core::Activity.new("d", "Turn A on lathe", 30) }
    let(:activity_e) { CpmSolver::Core::Activity.new("e", "Turn B on lathe", 20) }
    let(:activity_f) { CpmSolver::Core::Activity.new("f", "Polish B", 40) }
    let(:activity_g) { CpmSolver::Core::Activity.new("g", "Assemble A and B", 20) }
    let(:activity_h) { CpmSolver::Core::Activity.new("h", "Finish", 0) }

    before do
      program.add_activity(activity_a)
      program.add_activity(activity_b)
      program.add_activity(activity_c)
      program.add_activity(activity_d)
      program.add_activity(activity_e)
      program.add_activity(activity_f)
      program.add_activity(activity_g)
      program.add_activity(activity_h)

      program.add_predecessors(activity_b, [ activity_a ])
      program.add_predecessors(activity_c, [ activity_a ])
      program.add_predecessors(activity_d, [ activity_b, activity_c ])
      program.add_predecessors(activity_e, [ activity_b, activity_c ])
      program.add_predecessors(activity_f, [ activity_e ])
      program.add_predecessors(activity_g, [ activity_d, activity_f ])
      program.add_predecessors(activity_h, [ activity_g ])

      # Add validation before solving
      program.validate
      expect(program.validation_errors).to be_empty
      program.solve
    end

    it "should display summary" do
      expect(program.to_s).to_not eq ""
    end

    it "should generate a directed diagram as pdf file" do
      program.dependency_diagram
      expect(File.exist?(File.join(tmp_dir, "#{program.name}.pdf"))).to be true
    end

    it "should identify critical path activities" do
      expect(activity_a.critical).to be true
      expect(activity_b.critical).to be false
      expect(activity_c.critical).to be true
      expect(activity_d.critical).to be false
      expect(activity_e.critical).to be true
      expect(activity_f.critical).to be true
      expect(activity_g.critical).to be true
      expect(activity_h.critical).to be true
    end
  end

  context "with house program data" do
    # Source: https://hbr.org/1963/09/the-abcs-of-the-critical-path-method
    let(:program) { CpmSolver::Core::Program.new("HBR Program") }
    let(:start_date) { Date.new(2020, 3, 1) }
    let(:activity_a) { CpmSolver::Core::Activity.new("a", "Start", 0) }
    let(:activity_b) { CpmSolver::Core::Activity.new("b", "Excavate and pour footers", 4) }
    let(:activity_c) { CpmSolver::Core::Activity.new("c", "Pour concrete foundation", 2) }
    let(:activity_d) { CpmSolver::Core::Activity.new("d", "Erect wooden frame including rough roof", 4) }
    let(:activity_e) { CpmSolver::Core::Activity.new("e", "Lay brickwork", 6) }
    let(:activity_f) { CpmSolver::Core::Activity.new("f", "Install basement drains and plumbing", 1) }
    let(:activity_g) { CpmSolver::Core::Activity.new("g", "Pour basement floor", 2) }
    let(:activity_h) { CpmSolver::Core::Activity.new("h", "Install rough plumbing", 3) }
    let(:activity_i) { CpmSolver::Core::Activity.new("i", "Install rough wiring", 2) }
    let(:activity_j) { CpmSolver::Core::Activity.new("j", "Install heating and ventilating", 4) }
    let(:activity_k) { CpmSolver::Core::Activity.new("k", "Fasten plaster board and plaster (including drying)", 10) }
    let(:activity_l) { CpmSolver::Core::Activity.new("l", "Lay finish flooring", 3) }
    let(:activity_m) { CpmSolver::Core::Activity.new("m", "Install kitchen fixtures", 1) }
    let(:activity_n) { CpmSolver::Core::Activity.new("n", "Install finish plumbing", 2) }
    let(:activity_o) { CpmSolver::Core::Activity.new("o", "Finish carpentry", 3) }
    let(:activity_p) { CpmSolver::Core::Activity.new("p", "Finish roofing and flashing", 2) }
    let(:activity_q) { CpmSolver::Core::Activity.new("q", "Fasten gutters and downspouts", 1) }
    let(:activity_r) { CpmSolver::Core::Activity.new("r", "Lay storm drains for rain water", 1) }
    let(:activity_s) { CpmSolver::Core::Activity.new("s", "Sand and varnish flooring", 2) }
    let(:activity_t) { CpmSolver::Core::Activity.new("t", "Paint", 3) }
    let(:activity_u) { CpmSolver::Core::Activity.new("u", "Finish electrical work", 1) }
    let(:activity_v) { CpmSolver::Core::Activity.new("v", "Finish grading", 2) }
    let(:activity_w) { CpmSolver::Core::Activity.new("w", "Pour walks and complete landscaping", 5) }
    let(:activity_x) { CpmSolver::Core::Activity.new("x", "Finish", 0) }

    before do
      program.add_activity(activity_a)
      program.add_activity(activity_b)
      program.add_activity(activity_c)
      program.add_activity(activity_d)
      program.add_activity(activity_e)
      program.add_activity(activity_f)
      program.add_activity(activity_g)
      program.add_activity(activity_h)
      program.add_activity(activity_i)
      program.add_activity(activity_j)
      program.add_activity(activity_k)
      program.add_activity(activity_l)
      program.add_activity(activity_m)
      program.add_activity(activity_n)
      program.add_activity(activity_o)
      program.add_activity(activity_p)
      program.add_activity(activity_q)
      program.add_activity(activity_r)
      program.add_activity(activity_s)
      program.add_activity(activity_t)
      program.add_activity(activity_u)
      program.add_activity(activity_v)
      program.add_activity(activity_w)
      program.add_activity(activity_x)

      program.add_predecessors(activity_b, [ activity_a ])
      program.add_predecessors(activity_c, [ activity_b ])
      program.add_predecessors(activity_d, [ activity_c ])
      program.add_predecessors(activity_e, [ activity_d ])
      program.add_predecessors(activity_f, [ activity_c ])
      program.add_predecessors(activity_g, [ activity_f ])
      program.add_predecessors(activity_h, [ activity_f ])
      program.add_predecessors(activity_i, [ activity_d ])
      program.add_predecessors(activity_j, [ activity_d, activity_g ])
      program.add_predecessors(activity_k, [ activity_i, activity_j, activity_h ])
      program.add_predecessors(activity_l, [ activity_k ])
      program.add_predecessors(activity_m, [ activity_l ])
      program.add_predecessors(activity_n, [ activity_l ])
      program.add_predecessors(activity_o, [ activity_l ])
      program.add_predecessors(activity_p, [ activity_e ])
      program.add_predecessors(activity_q, [ activity_p ])
      program.add_predecessors(activity_r, [ activity_c ])
      program.add_predecessors(activity_s, [ activity_o, activity_t ])
      program.add_predecessors(activity_t, [ activity_m, activity_n ])
      program.add_predecessors(activity_u, [ activity_t ])
      program.add_predecessors(activity_v, [ activity_q, activity_r ])
      program.add_predecessors(activity_w, [ activity_v ])
      program.add_predecessors(activity_x, [ activity_s, activity_u, activity_w ])

      # Add validation before solving
      program.validate
      expect(program.validation_errors).to be_empty
      program.solve
    end

    it "should display summary" do
      expect(program.to_s).to_not eq ""
    end

    it "should generate a directed diagram as pdf file" do
      program.dependency_diagram
      expect(File.exist?(File.join(tmp_dir, "#{program.name}.pdf"))).to be true
    end

    it "should identify critical path activities" do
      critical = {
        "a" => true, "b" => true, "c" => true, "d" => true, "e" => false, "f" => false, "g" => false, "h" => false,
        "i" => false, "j" => true, "k" => true, "l" => true, "m" => false, "n" => true, "o" => false, "p" => false,
        "q" => false, "r" => false, "s" => true, "t" => true, "u" => false, "v" => false, "w" => false, "x" => true
      }
      program.activities.each_value do |activity|
        expect(activity.critical).to eq(critical[activity.reference]), "Activity #{activity.reference} is not critical"
      end
    end
  end
end
