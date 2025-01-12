

require "terminal-table"
require "graphviz"

module CpmSolver
  # Modelled as Directed Acyclic Graph (DAG)
  class Program
    attr_accessor :name, :activities
    attr_reader :status, :validation_errors

    STATUS = { setup: 0, validated: 1, solved: 2, invalid: 3 }.freeze

    def initialize(name)
      @name = name
      @activities = {}
      @status = STATUS[:setup]
    end

    # Add an activity to the program
    def add_activitity(activity)
      @activities[activity.reference] = activity
      @status = STATUS[:setup]
    end

    # Add array of predecessors to an activity
    def add_predecessors(activity, predecessors = [])
      predecessors.each do |predecessor|
        @activities[activity.reference].add_predecessor(predecessor)
        predecessor.add_successor(activity)
      end
      @status = STATUS[:setup]
    end

    # Activities with no predecessors
    def start_activities
      @activities.select { |_key, activity| activity.predecessors.empty? }
    end

    # Activities with no successors
    def end_activities
      @activities.select { |_key, activity| activity.successors.empty? }
    end

    def validate
      @validation_errors = []
      @validation_errors << "No start activities found" if start_activities.empty?
      @validation_errors << "More than one start activity found" if start_activities.size > 1
      @validation_errors << "No end activities found" if end_activities.empty?
      @validation_errors << "More than one end activity found" if end_activities.size > 1
      @validation_errors << "No activities found" if @activities.empty?
      if @activities.any? { |_key, activity| activity.predecessors.empty? && activity.successors.empty? }
        @validation_errors << "Some activities have no predecessors or successors"
      end

      @status = if @validation_errors.empty?
        STATUS[:validated]
      else
        STATUS[:invalid]
      end
      @validation_errors
    end

    # Calculate the critical path
    def solve
      validate
      raise "Program not validated" unless @status == STATUS[:validated]

      forward_pass
      backward_pass
      calculate_slack
      @status = STATUS[:solved]
    end

    # Activities with zero slack
    def critical_path_activities
      raise "Program not solved" unless @status == STATUS[:solved]

      @activities.select { |_key, activity| activity.slack.zero? }
    end

    # Summary table of activities
    def summary_table
      labels = %w[
        Ref
        Name
        Duration
        Slack
        Critical
        Predecessors
        Successors
        Early_Start
        Early_Finish
        Late_Start
        Late_Finish
      ]

      contents = @activities.each_value.map do |activity|
        [
          activity.reference,
          activity.name,
          activity.duration,
          activity.slack,
          activity.critical,
          activity.predecessors.join(" "),
          activity.successors.join(" "),
          activity.early_start.to_s,
          activity.early_finish.to_s,
          activity.late_start.to_s,
          activity.late_finish.to_s
        ]
      end

      table = Terminal::Table.new(title: "Program: #{name}", headings: labels, rows: contents)
      table.align_column(2, :center)
      table.align_column(3, :center)
      table
    end

    # Graphviz diagram of the program
    def dependency_diagram
      dwg = GraphViz.new(:G, type: :digraph)
      dwg.node[:fontname] = "Helvetica"
      dwg.node[:shape] = "record"

      build_graphviz(dwg)
      dwg.output(pdf: "#{name}.pdf")
    end

    private

    # Forward pass to calculate early times
    def forward_pass
      recalc_early_times = true

      while recalc_early_times
        recalc_early_times = false
        @activities.each_value.with_index do |activity, index|
          if index.zero?
            activity.early_start = 0
          else
            # Check if predecessors uncalculated
            activity.predecessors.each do |predecessor|
              recalc_early_times = true if @activities[predecessor].early_finish.nil?
            end

            predecessors = activity.predecessors.map { |ref| @activities[ref] }
            latest_finish_date = predecessors.map(&:early_finish).compact.max
            activity.early_start = latest_finish_date
          end
          activity.early_finish = activity.early_start + activity.duration
        end
      end
      @status = STATUS[:setup]
      @status
    end

    # Backward pass to calculate late times
    def backward_pass
      # First, set all activities' late times to nil
      @activities.each_value do |activity|
        activity.late_start = nil
        activity.late_finish = nil
      end

      # Initialize end activities with their early finish times
      end_activities.each_value do |activity|
        activity.late_finish = activity.early_finish
        activity.late_start = activity.late_finish - activity.duration
      end

      # Keep processing until all activities have been calculated
      until @activities.values.all? { |a| a.late_start && a.late_finish }
        @activities.values.reverse_each do |activity|
          # Skip if already calculated
          next if activity.late_start && activity.late_finish
          # Skip if any successor hasn't been calculated yet
          next if activity.successors.any? { |ref| @activities[ref].late_start.nil? }

          # All successors have been calculated, so we can calculate this activity
          earliest_successor_start = activity.successors.map { |ref| @activities[ref].late_start }.min
          activity.late_finish = earliest_successor_start
          activity.late_start = activity.late_finish - activity.duration
        end
      end
      @status = STATUS[:setup]
      @status
    end

    # Calculate slack for all activities
    def calculate_slack
      @activities.each_value(&:slack)
      @status = STATUS[:setup]
      @status
    end

    def build_graphviz(dwg)
      @activities.each_value do |activity|
        label = node_label(activity)

        if activity.critical
          dwg.add_nodes(activity.to_s, label:, style: "rounded, filled", fillcolor: "orange1")
        else
          dwg.add_nodes(activity.to_s, label:, style: "rounded")
        end

        activity.predecessors.each do |predecessor|
          dwg.add_edges(@activities[predecessor].to_s, activity.to_s)
        end
      end
    end

    def node_label(activity)
      title = "#{activity.reference}\\n#{activity.name}|"
      duration = activity.duration || 0
      es = activity.early_start || 0
      ef = activity.early_finish || 0
      ls = activity.late_start || 0
      lf = activity.late_finish || 0
      slack = activity.slack || 0

      "{{ES: #{es} | D: #{duration} | EF: #{ef}} | Activity: #{title}| {LS: #{ls} | S: #{slack} | LF: #{lf}}}"
    end
  end
end
