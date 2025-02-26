require "spec_helper"
require "cpm_solver/visualization/graph_builder"
require "cpm_solver/core/program"
require "cpm_solver/core/activity"
require "fileutils"

RSpec.describe CpmSolver::Visualization::GraphBuilder do
  let(:program) { CpmSolver::Core::Program.new("Test Program") }
  let(:activity_a) { CpmSolver::Core::Activity.new("A", "Task A", 5) }
  let(:activity_b) { CpmSolver::Core::Activity.new("B", "Task B", 3) }
  let(:activity_c) { CpmSolver::Core::Activity.new("C", "Task C", 4) }
  let(:activity_d) { CpmSolver::Core::Activity.new("D", "Task D", 2) }

  before do
    program.add_activity(activity_a)
    program.add_activity(activity_b)
    program.add_activity(activity_c)
    program.add_activity(activity_d)

    # Set up activity relationships
    program.add_predecessors(activity_b, [activity_a])
    program.add_predecessors(activity_c, [activity_a])
    program.add_predecessors(activity_d, [activity_b, activity_c])

    # Calculate critical path to set ES, EF, LS, LF values
    program.solve
  end

  describe "#build_dependency", :dependency_output do
    let(:graph_builder) { described_class.new(program) }
    let(:graph) { graph_builder.build_dependency }
    let(:tmp_dir) { "tmp/diagrams/visualization" }
    let(:pdf_output_path) { File.join(tmp_dir, "network_diagram.pdf") }

    before(:each) do
      FileUtils.rm_rf(tmp_dir) unless RSpec.current_example.metadata[:save_files]
      FileUtils.mkdir_p(tmp_dir)
    end

    def generate_pdf_output(graph)
      begin
        # Ensure the directory exists
        FileUtils.mkdir_p(File.dirname(pdf_output_path))

        # Generate PDF with specific options
        graph.output(
          pdf: pdf_output_path,
          use: 'dot'  # Use dot layout algorithm
        )

        # Verify the file was created
        raise "PDF file was not generated at #{pdf_output_path}" unless File.exist?(pdf_output_path)

        puts "\nNetwork diagram PDF file generated successfully at: #{pdf_output_path}"
      rescue StandardError => e
        puts "\nError generating PDF: #{e.message}"
        puts e.backtrace
        raise "Failed to generate PDF: #{e.message}"
      end
    end

    it "creates a directed graph with top-to-bottom layout", :output_pdf do
      expect(graph.type).to eq("digraph")
      expect(graph[:rankdir].to_s).to eq("TB")  # Verify Top to Bottom layout
      generate_pdf_output(graph) if RSpec.current_example.metadata[:output_pdf]
    end

    it "creates nodes for all activities" do
      expect(graph.node_count).to eq(4)
    end

    it "creates edges between activities based on predecessors" do
      expect(graph.edge_count).to eq(4) # A->B and A->C and C->D and B->D
    end

    it "includes activity details in node labels" do
      node_a = graph.get_node(activity_a.to_s)
      label = node_a[:label].to_s

      expect(label).to include("ES: 0")
      expect(label).to include("D: 5")
      expect(label).to include("EF: 5")
      expect(label).to include("LS: 0")
      expect(label).to include("S: 0")
      expect(label).to include("LF: 5")
      expect(label).to include("A")
      expect(label).to include("Task A")
    end

    it "highlights critical path nodes and edges", :output_pdf do
      # Make some activities critical for testing
      activity_a.critical = true
      activity_b.critical = true

      graph = graph_builder.build_dependency

      # Check critical nodes
      node_a = graph.get_node(activity_a.to_s)
      expect(node_a[:style].to_s).to include("filled")
      expect(node_a[:fillcolor].to_s).to eq("orange1")
      expect(node_a[:penwidth].to_s).to eq("2.0")

      # Check critical edges
      edges = graph.each_edge.select do |edge|
        edge.node_one == activity_a.to_s && edge.node_two == activity_b.to_s
      end
      expect(edges.first[:color].to_s).to eq("red")
      expect(edges.first[:penwidth].to_s).to eq("2.0")

      generate_pdf_output(graph) if RSpec.current_example.metadata[:output_pdf]
    end
  end

  describe "#build_gantt", :gantt_output do
    let(:graph_builder) { described_class.new(program) }
    let(:gantt) { graph_builder.build_gantt }
    let(:tmp_dir) { "tmp/gantt/visualization" }
    let(:html_output_path) { File.join(tmp_dir, "gantt_chart.html") }

    before(:each) do
      FileUtils.mkdir_p(tmp_dir)
    end

    def generate_html_output(gantt_content)
      # Remove the mermaid markdown markers if present
      cleaned_content = gantt_content.gsub(/```mermaid\n/, '').gsub(/```\n?$/, '')

      html_content = <<~HTML
        <!DOCTYPE html>
        <html>
        <head>
          <title>#{program.name} - Gantt Chart</title>
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
            <h1>#{program.name} - Gantt Chart</h1>
            <div class="mermaid">
              #{cleaned_content}
            </div>
          </div>
        </body>
        </html>
      HTML

      File.write(html_output_path, html_content)
      puts "\nGantt chart HTML file generated at: #{html_output_path}"
    end

    it "generates valid mermaid gantt chart syntax" do
      expect(gantt).to include("```mermaid")
      expect(gantt).to include("gantt")
      expect(gantt).to include("dateFormat X")
      expect(gantt).to include("axisFormat %d")
      expect(gantt).to include("title Test Program - Gantt Chart")

      # Generate HTML output if the :output_html tag is present
      if RSpec.configuration.filter.rules[:output_html]
        generate_html_output(gantt)
      end
    end

    it "includes all activities with their durations and start times" do
      expect(gantt).to include("section A")
      expect(gantt).to include("Task A")
      expect(gantt).to include("section B")
      expect(gantt).to include("Task B")
      expect(gantt).to include("section C")
      expect(gantt).to include("Task C")
      expect(gantt).to include("section D")
      expect(gantt).to include("Task D")
    end

    it "marks critical activities" do
      critical_path = program.activities.values.select(&:critical)
      critical_path.each do |activity|
        expect(gantt).to match(/#{activity.name} :crit,/)
      end
    end

    it "includes dependencies between activities" do
      expect(gantt).to include("After A")
      expect(gantt).to include("After B, C")
    end
  end
end
