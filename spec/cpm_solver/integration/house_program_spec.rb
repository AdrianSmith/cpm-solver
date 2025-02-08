require "spec_helper"

RSpec.describe "House Construction Program Integration", :integration do
  let(:csv_file) { "spec/test_data/house_100.csv" }
  let(:program_name) { "House Construction" }
  let(:tmp_dir) { "tmp/diagrams" }

  before(:all) do
    @verbose = ENV['VERBOSE'] == 'true'
    @tmp_dir = "tmp/diagrams"
    # Create output directory for logs
    @output_dir = "tmp/output"
    FileUtils.mkdir_p(@output_dir) if @verbose

    # Clean up existing output files
    if @verbose
      Dir.glob(File.join(@output_dir, "*_output.txt")).each do |file|
        File.delete(file)
      end
    end
  end

  def log(message)
    if @verbose && @output_file && !@output_file.closed?
      @output_file.puts(message)
      @output_file.flush  # Ensure content is written immediately
    end
  end

  shared_examples "solver behavior" do |solver_class|
    let(:program) { CpmSolver::Core::Program.new(program_name) }
    let(:reader) { CpmSolver::IO::CsvReader.new(csv_file) }
    let(:solver_name) { solver_class.name.split("::").last }
    let(:pdf_filename) { File.join(@tmp_dir, "#{program_name} - #{solver_name}.pdf") }
    let(:output_filename) { File.join(@output_dir, "#{solver_name}_output.txt") }

    before(:each) do
      if @verbose
        @output_file = File.open(output_filename, 'w')
        log "\n=== #{solver_name} Solver Output ===\n"
      end

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

      # Write initial program summary only once
      if @verbose
        log "\nProgram Summary:"
        log program.summary_table
      end
    end

    after(:each) do
      if @output_file && !@output_file.closed?
        @output_file.close
      end

      unless @verbose
        # Clean up PDF files after each test
        File.delete(pdf_filename) if File.exist?(pdf_filename)
      end
    end

    it "generates a dependency diagram" do
      allow(program).to receive(:name).and_return("#{program_name} - #{solver_name}")
      program.dependency_diagram
      expect(File.exist?(pdf_filename)).to be true
      log "\nGenerated PDF diagram: #{pdf_filename}" if @verbose
    end

    it "identifies critical activities" do
      critical_activities = program.critical_path_activities
      expect(critical_activities).not_to be_empty

      if @verbose
        log "\nCritical Path Activities:"
        critical_activities.each_value do |activity|
          log "#{activity.reference} - #{activity.name} (Duration: #{activity.duration})"
          @output_file.flush
        end
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
      expect(program.summary_table).not_to be_nil
    end
  end

  context "with Critical-Path solver" do
    include_examples "solver behavior", CpmSolver::Solvers::CriticalPath
  end

  context "with Floyd-Warshall solver" do
    include_examples "solver behavior", CpmSolver::Solvers::FloydWarshall
  end

  context "with Topological solver" do
    include_examples "solver behavior", CpmSolver::Solvers::Topological
  end

  context "with Dijkstra solver" do
    include_examples "solver behavior", CpmSolver::Solvers::Dijkstra
  end

  after(:all) do
    if @verbose
      if Dir.exist?(@tmp_dir)
        pdf_files = Dir.glob(File.join(@tmp_dir, "*.pdf"))
        if pdf_files.any?
          puts "\nGenerated PDF files:"
          pdf_files.each { |file| puts "- #{file}" }
        end
      end

      if Dir.exist?(@output_dir)
        output_files = Dir.glob(File.join(@output_dir, "*.txt"))
        if output_files.any?
          puts "\nGenerated output files:"
          output_files.each { |file| puts "- #{file}" }
        end
      end
    end
  end
end
