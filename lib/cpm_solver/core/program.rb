require "terminal-table"
require_relative "../visualization/graph_builder"

module CpmSolver
  module Core
    # Modelled as Directed Acyclic Graph (DAG)
    class Program
      attr_accessor :name, :activities
      attr_reader :status, :validation_errors

      STATUS = {
        new: :new,
        validated: :validated,
        invalid: :invalid,
        solved: :solved
      }.freeze

      def initialize(name)
        @name = name
        @activities = {}
        @status = STATUS[:new]
      end

      # Add an activity to the program
      def add_activity(activity)
        @activities[activity.reference] = activity
        @status = STATUS[:new]
      end

      # Add array of predecessors to an activity
      def add_predecessors(activity, predecessors = [])
        predecessors.each do |predecessor|
          @activities[activity.reference].add_predecessor(predecessor)
          predecessor.add_successor(activity)
        end
        @status = STATUS[:new]
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
      def solve(algorithm = :bellman_ford)
        validate
        raise "Program not validated" unless @status == STATUS[:validated]

        solver = CpmSolver::Solvers::BellmanFord.new(self)
        solver.solve
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
        graph = Visualization::GraphBuilder.new(self).build
        graph.output(pdf: "#{name}.pdf")
      end
    end
  end
end
