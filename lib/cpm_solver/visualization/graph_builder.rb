require "graphviz"
require "set"

module CpmSolver
  module Visualization
    class GraphBuilder
      def initialize(program)
        @program = program
      end

      def build_dependency
        # Initialize GraphViz with specific settings for better PDF output
        dwg = GraphViz.new(:G, type: :digraph) do |g|
          g.node[:fontname] = "Helvetica"
          g.node[:shape] = "record"
          g.edge[:fontname] = "Helvetica"
          g.edge[:fontsize] = 10
          g[:rankdir] = "TB"  # Top to Bottom layout
          g[:splines] = "ortho"  # Orthogonal lines
          g[:concentrate] = "true"  # Concentrate edges
        end

        # Track added edges to prevent duplicates
        added_edges = Set.new

        @program.activities.each_value do |activity|
          label = node_label(activity)

          # Style critical path nodes differently
          if activity.critical
            dwg.add_nodes(activity.to_s,
              label: label,
              style: "rounded,filled",
              fillcolor: "orange1",
              penwidth: "2.0"
            )
          else
            dwg.add_nodes(activity.to_s,
              label: label,
              style: "rounded"
            )
          end

          activity.predecessors.each do |predecessor|
            # For directed graphs, edge direction matters, so don't sort
            edge_key = "#{predecessor}->#{activity}"
            unless added_edges.include?(edge_key)
              # Style critical path edges differently
              if activity.critical && @program.activities[predecessor].critical
                dwg.add_edges(
                  @program.activities[predecessor].to_s,
                  activity.to_s,
                  color: "red",
                  penwidth: "2.0"
                )
              else
                dwg.add_edges(
                  @program.activities[predecessor].to_s,
                  activity.to_s
                )
              end
              added_edges.add(edge_key)
            end
          end
        end

        dwg
      end

      def build_gantt
        activities = @program.activities.values.sort_by(&:early_start)

        lines = ["```mermaid",
                "gantt",
                "    dateFormat X",
                "    axisFormat %d",
                "    title #{@program.name} - Gantt Chart",
                ""]

        activities.each do |activity|
          duration = activity.duration || 0
          es = activity.early_start || 0
          critical = activity.critical ? "crit, " : ""

          # Add proper indentation and section for each activity
          lines << "    section #{activity.reference}"
          lines << "    #{activity.name} :#{critical}#{es}, #{duration}d"

          # Add dependencies with proper indentation
          unless activity.predecessors.empty?
            deps = activity.predecessors.join(", ")
            lines << "    After #{deps} :#{es}, #{duration}d"
          end
        end

        lines << "```"
        lines.join("\n")
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
