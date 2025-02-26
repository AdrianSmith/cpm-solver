require "spec_helper"

RSpec.describe "House Construction Program Integration", :integration do
  let(:csv_file) { "spec/test_data/house_100.csv" }
  let(:program_name) { "House Construction" }
  let(:tmp_dir) { "tmp/diagrams/house" }
  let(:gantt_dir) { "tmp/gantt/house" }
  let(:output_dir) { "tmp/output/house" }
  let(:pdf_filename) { File.join(tmp_dir, "#{program_name}.pdf") }
  let(:gantt_filename) { File.join(gantt_dir, "#{program_name}_gantt.html") }

  before(:all) do
    @tmp_dir = "tmp/diagrams/house"
    @gantt_dir = "tmp/gantt/house"
    @output_dir = "tmp/output/house"

    # Clean up any existing files
    FileUtils.rm_rf(@tmp_dir)
    FileUtils.rm_rf(@gantt_dir)
    FileUtils.rm_rf(@output_dir)

    # Create fresh directories
    FileUtils.mkdir_p(@tmp_dir)
    FileUtils.mkdir_p(@gantt_dir)
    FileUtils.mkdir_p(@output_dir)
  end

  def log(message)
    return unless RSpec.current_example.metadata[:output]
    if @output_file && !@output_file.closed?
      @output_file.puts(message)
      @output_file.flush
    end
  end

  shared_examples "solver behavior" do |solver_class|
    let(:program) { CpmSolver::Core::Program.new(program_name) }
    let(:reader) { CpmSolver::IO::CsvReader.new(csv_file) }
    let(:solver_name) { solver_class.name.split("::").last }
    let(:output_filename) { File.join(@output_dir, "#{solver_name}_output.txt") }

    before(:each) do
      FileUtils.mkdir_p(@output_dir)
      FileUtils.mkdir_p(tmp_dir)

      if RSpec.current_example.metadata[:output]
        @output_file = File.open(output_filename, 'w')
        log "\n=== #{solver_name} Solver Output ===\n"
      end

      # Verify CSV file exists
      unless File.exist?(csv_file)
        raise "CSV file not found: #{csv_file}"
      end

      # Read and set up activities
      activities = reader.read
      activities.each do |_ref, activity|
        program.add_activity(activity)
      end

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

      # Use the provided solver class to solve the program
      @solver = solver_class.new(program)
      @solver.solve

      # Write initial program summary only once
      if RSpec.current_example.metadata[:output]
        log "\nProgram Summary:"
        log program.summary_table
      end
    end

    after(:each) do
      @output_file&.close
    end

    # Only run the dependency diagram test for the Critical Path solver
    if solver_class == CpmSolver::Solvers::CriticalPath
      it "generates a dependency diagram and gantt chart" do
        # Verify start and end activities
        start_activities = program.start_activities
        end_activities = program.end_activities

        expect(start_activities).not_to be_empty
        expect(end_activities).not_to be_empty

        # Verify critical path connects start to end
        critical_activities = program.critical_path_activities
        expect(critical_activities).not_to be_empty

        # Check if start activity is in critical path
        start_critical = critical_activities.values.any? { |a| start_activities.values.include?(a) }
        expect(start_critical).to be(true), "Critical path should include a start activity"

        # Check if end activity is in critical path
        end_critical = critical_activities.values.any? { |a| end_activities.values.include?(a) }
        expect(end_critical).to be(true), "Critical path should include an end activity"

        # Generate the dependency diagram
        graph_builder = CpmSolver::Visualization::GraphBuilder.new(program)
        graph = graph_builder.build_dependency

        # Ensure directories exist
        FileUtils.mkdir_p(File.dirname(pdf_filename))
        FileUtils.mkdir_p(File.dirname(gantt_filename))

        # Generate the PDF
        graph.output(pdf: pdf_filename)
        expect(File.exist?(pdf_filename)).to be true

        # Generate the Gantt chart
        gantt_content = graph_builder.build_gantt
        generate_gantt_html(gantt_content, gantt_filename, program_name)
        expect(File.exist?(gantt_filename)).to be true

        if RSpec.current_example.metadata[:output]
          log "\nProgram Structure:"
          log "  Start activities: #{start_activities.keys.join(', ')}"
          log "  End activities: #{end_activities.keys.join(', ')}"
          log "\nCritical Path Analysis:"
          log "  Total activities: #{program.activities.size}"
          log "  Critical activities: #{critical_activities.size}"
          log "\nCritical Path:"
          critical_activities.each do |ref, activity|
            predecessors = activity.predecessors.select { |p| program.activities[p]&.critical }
            log "  #{ref} - #{activity.name}"
            log "    Duration: #{activity.duration}"
            log "    ES: #{activity.early_start}, EF: #{activity.early_finish}"
            log "    LS: #{activity.late_start}, LF: #{activity.late_finish}"
            log "    Critical predecessors: #{predecessors.join(', ')}"
          end
          log "\nGenerated files:"
          log "  PDF diagram: #{pdf_filename}"
          log "  Gantt chart: #{gantt_filename}"
        end
      end
    end

    it "identifies critical activities" do
      critical_activities = program.critical_path_activities
      expect(critical_activities).not_to be_empty

      if RSpec.current_example.metadata[:output]
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

  def generate_gantt_html(gantt_content, output_path, title)
    # Remove the mermaid markdown markers if present
    cleaned_content = gantt_content.gsub(/```mermaid\n/, '').gsub(/```\n?$/, '')

    html_content = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>#{title} - Gantt Chart</title>
        <script src="https://cdn.jsdelivr.net/npm/mermaid@11.4.1/dist/mermaid.min.js"></script>
        <script>
          mermaid.initialize({
            startOnLoad: true,
            theme: 'default',
            gantt: {
              titleTopMargin: 25,
              barHeight: 20,
              barGap: 4,
              topPadding: 50,
              sidePadding: 50
            }
          });
        </script>
        <style>
          body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
          }
          .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
          }
          h1 {
            color: #333;
            text-align: center;
            margin-bottom: 30px;
          }
          .mermaid {
            background: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>#{title} - Gantt Chart</h1>
          <div class="mermaid">
            #{cleaned_content}
          </div>
        </div>
      </body>
      </html>
    HTML

    File.write(output_path, html_content)
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
    # Show generated files if they exist
    if Dir.exist?(@tmp_dir)
      pdf_files = Dir.glob(File.join(@tmp_dir, "*.pdf"))
      if pdf_files.any?
        puts "\nGenerated PDF files:"
        pdf_files.each { |file| puts "- #{file}" }
      end
    end

    if Dir.exist?(@gantt_dir)
      gantt_files = Dir.glob(File.join(@gantt_dir, "*.html"))
      if gantt_files.any?
        puts "\nGenerated Gantt files:"
        gantt_files.each { |file| puts "- #{file}" }
      end
    end

    if Dir.exist?(@output_dir)
      output_files = Dir.glob(File.join(@output_dir, "*.txt"))
      if output_files.any?
        puts "\nGenerated output files:"
        output_files.each { |file| puts "- #{file}" }
      end
    end

    # Only clean up if :save_files tag is NOT present
    unless RSpec.configuration.filter.rules[:save_files]
      FileUtils.rm_rf(@tmp_dir)
      FileUtils.rm_rf(@gantt_dir)
      FileUtils.rm_rf(@output_dir)
    end
  end
end
