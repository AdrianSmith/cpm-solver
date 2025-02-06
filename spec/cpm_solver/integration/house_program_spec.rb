require "spec_helper"

RSpec.describe "House Construction Program Integration" do
  let(:csv_file) { "spec/test_data/house_100.csv" }
  let(:program_name) { "House Construction" }
  let(:tmp_dir) { "tmp/diagrams" }
  # Check for KEEP_PDFS environment variable
  let(:keep_pdfs) { ENV['KEEP_PDFS'] == 'true' }

  shared_examples "solver behavior" do |solver_class|
    let(:program) { CpmSolver::Core::Program.new(program_name) }
    let(:reader) { CpmSolver::IO::CsvReader.new(csv_file) }
    let(:solver_name) { solver_class.name.split("::").last }
    let(:pdf_filename) { File.join(tmp_dir, "#{program_name} - #{solver_name}.pdf") }

    before do
      # Create tmp directory
      FileUtils.mkdir_p(tmp_dir)

      # Verify CSV file exists
      unless File.exist?(csv_file)
        raise "CSV file not found: #{csv_file}"
      end

      # Read activities from CSV
      activities = reader.read

      if activities.empty?
        raise "No activities were read from the CSV file"
      end

      # Add activities to program
      activities.each do |_ref, activity|
        program.add_activity(activity)
      end

      # Add predecessors
      activities.each do |_ref, activity|
        predecessors = activity.predecessors.map { |ref| activities[ref] }.compact
        program.add_predecessors(activity, predecessors) unless predecessors.empty?
      end

      # Validate program before solving
      program.validate
      if program.validation_errors.any?
        puts "\nValidation errors:"
        program.validation_errors.each { |error| puts "- #{error}" }
      end

      # Solve using specified solver
      @solver = solver_class.new(program)
      @solver.solve
    end

    after do
      unless keep_pdfs
        # Clean up PDF files after each test
        File.delete(pdf_filename) if File.exist?(pdf_filename)

        # Optionally remove the directory if it's empty
        FileUtils.rm_r(tmp_dir) if Dir.empty?(tmp_dir)
        FileUtils.rm_r("tmp") if Dir.exist?("tmp") && Dir.empty?("tmp")
      end
    end

    it "generates a dependency diagram" do
      # Override the default PDF filename with solver-specific one
      allow(program).to receive(:name).and_return("#{program_name} - #{solver_name}")

      program.dependency_diagram
      expect(File.exist?(pdf_filename)).to be true

      puts "\nGenerated PDF diagram: #{pdf_filename}"
      puts "PDF files will be #{keep_pdfs ? 'retained' : 'deleted'} after tests"
    end

    it "identifies critical activities" do
      critical_activities = program.critical_path_activities
      expect(critical_activities).not_to be_empty

      # Print critical path for debugging
      puts "\nCritical Path Activities for #{solver_class}:"
      critical_activities.each do |_ref, activity|
        puts "#{activity.reference} - #{activity.name} (Duration: #{activity.duration})"
      end
    end

    it "calculates early and late dates for all activities" do
      program.activities.each_value do |activity|
        expect(activity.early_start).not_to be_nil
        expect(activity.early_finish).not_to be_nil
        expect(activity.late_start).not_to be_nil
        expect(activity.late_finish).not_to be_nil
      end
    end

    it "displays program summary" do
      puts "\nProgram Summary for #{solver_class}:"
      puts program.summary_table
    end
  end

  context "with Bellman-Ford solver" do
    include_examples "solver behavior", CpmSolver::Solvers::BellmanFord
  end

  context "with Floyd-Warshall solver" do
    include_examples "solver behavior", CpmSolver::Solvers::FloydWarshall
  end
end
