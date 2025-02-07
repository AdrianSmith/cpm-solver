require "graphviz"
require "set"

module CpmSolver
  module Visualization
    class GraphBuilder
      def initialize(program)
        @program = program
      end

      def build
        dwg = GraphViz.new(:G, type: :digraph)
        dwg.node[:fontname] = "Helvetica"
        dwg.node[:shape] = "record"

        # Track added edges to prevent duplicates
        added_edges = Set.new

        @program.activities.each_value do |activity|
          label = node_label(activity)

          if activity.critical
            dwg.add_nodes(activity.to_s, label:, style: "rounded, filled", fillcolor: "orange1")
          else
            dwg.add_nodes(activity.to_s, label:, style: "rounded")
          end

          activity.predecessors.each do |predecessor|
            # For directed graphs, edge direction matters, so don't sort
            edge_key = "#{predecessor}->#{activity}"
            unless added_edges.include?(edge_key)
              dwg.add_edges(@program.activities[predecessor].to_s, activity.to_s)
              added_edges.add(edge_key)
            end
          end
        end

        dwg
      end

      private

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
end
