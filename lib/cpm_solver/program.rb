# frozen_string_literal: true

require 'terminal-table'
require 'graphviz'
require 'pry'

module CpmSolver
  # Modelled as Directed Acyclic Graph (DAG)
  class Program
    attr_accessor :name, :activities

    def initialize(name)
      @name = name
      @activities = Hash.new { |hash, key| hash[key] = [] }
    end

    def add_activitity(activity)
      @activities[activity.reference] = activity
    end

    def add_predecessors(activity, predecessors = [])
      predecessors.each do |predecessor|
        @activities[activity.reference].add_predecessor(predecessor)
        predecessor.add_successor(activity)
      end
    end

    def critical_path_activities
      forward_pass
      backward_pass
      calculate_slack
      activities.select { |_key, activity| activity.slack.zero? }
    end

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
              recalc_early_times = true if predecessor.early_finish.nil?
            end

            latest_finish_date = activity.predecessors.map(&:early_finish).compact.max
            activity.early_start = latest_finish_date
          end
          activity.early_finish = activity.early_start + activity.duration
        end
      end
    end

    def backward_pass
      recalc_late_times = true

      while recalc_late_times
        recalc_late_times = false
        @activities.keys.reverse.each.with_index do |activity_ref, index|
          activity = @activities[activity_ref]

          if index.zero?
            activity.late_finish = activity.early_finish
          else
            # Check if successors uncalculated
            activity.successors.each do |successor|
              recalc_late_times = true if successor.late_start.nil?
            end

            earliest_start = activity.successors.map(&:late_start).compact.min
            activity.late_finish = earliest_start
          end
          activity.late_start = activity.late_finish - activity.duration
          # puts "#{activity_ref} | index: #{index} | late_start: #{activity.late_start} | late_finish: #{activity.late_finish}"
        end
      end
    end

    def calculate_slack
      @activities.each_value(&:slack)
    end

    def to_s
      labels = %w[Ref Name Duration Slack Critical Predecessors Successors Early_Start Early_Finish Late_Start
                  Late_Finish]
      contents = []
      @activities.each_value do |activity|
        contents << [
          activity.reference, activity.name, activity.duration, activity.slack, activity.critical,
          activity.predecessors.map(&:reference).join(' '),
          activity.successors.map(&:reference).join(' '),
          activity.early_start.to_s, activity.early_finish.to_s, activity.late_start.to_s, activity.late_finish.to_s
        ]
      end

      table = Terminal::Table.new(title: "Program: #{name}", headings: labels, rows: contents)
      table.align_column(2, :center)
      table.align_column(3, :center)
      table
    end

    def to_pdf
      dwg = GraphViz.new(:G, type: :digraph)
      dwg.node[:fontname] = 'Helvetica'
      dwg.node[:shape] = 'box'
      dwg.node[:style] = 'rounded'

      build_graphviz(dwg)
      dwg.output(pdf: "#{name}.pdf")
    end

    private

    def build_graphviz(dwg)
      @activities.each_value do |activity|
        dwg.add_nodes(activity.to_s)
        activity.predecessors.each do |predecessor|
          dwg.add_edges(predecessor.to_s, activity.to_s)
        end
      end
    end
  end
end
