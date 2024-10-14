require "terminal-table"

module CpmSolver
  class Program
    attr_accessor :name, :activities

    def initialize(name)
      @name = name
      @activities = Hash.new { |hash, key| hash[key] = [] }
    end

    def add_activitity(activity)
      @activities[activity.reference] = activity
    end

    def add_predecessors(activity, predecessors=[])
      predecessors.each do |predecessor|
        @activities[activity.reference].add_predecessor(predecessor)
        predecessor.add_successor(activity)
      end
    end

    def critical_path_activities
      forward_pass
      backward_pass
      calculate_slack
      activities.select { |key, activity| activity.slack == 0 }
    end

    def forward_pass
      @activities.keys.each.with_index do |activity_ref, index|
        activity = @activities[activity_ref]
        if index == 0
          activity.early_start = activity.planned_start
        else
          latest_finish_date = activity.predecessors.map(&:early_finish).compact.max
          activity.early_start = latest_finish_date
        end
        activity.early_finish = activity.early_start + activity.duration
      end
    end

    def backward_pass
      @activities.keys.reverse.each.with_index do |activity_ref, index|
        activity = @activities[activity_ref]

        if index == 0
          activity.late_finish = activity.early_finish
          activity.late_start = activity.late_finish - activity.duration
        end

        activity.successors.each do |successor|
          if successor.late_start
            activity.late_finish = successor.late_start
            activity.late_start = activity.late_finish - activity.duration
          end
        end
      end
    end

    def calculate_slack
      @activities.each do |_, activity|
        activity.slack
      end
    end

    def to_s
      labels = %w(Ref Name Duration Slack Critical Dependencies Planned_Start Planned_Finish Early_Start Early_Finish Late_Start Late_Finish)
      contents = []
      @activities.each do |_, activity|
        contents << [
          activity.reference,
          activity.name,
          activity.duration,
          activity.slack,
          activity.critical,
          activity.predecessors.map { |a| a.reference }.join(" "),
          activity.planned_start.to_s,
          activity.planned_finish.to_s,
          activity.early_start.to_s,
          activity.early_finish.to_s,
          activity.late_start.to_s,
          activity.late_finish.to_s,
        ]
      end

      table = Terminal::Table.new(
        title: "Program: #{name}",
        headings: labels,
        rows: contents,
      )
      table.align_column(2, :center)
      table.align_column(3, :center)
      table
    end

    def to_pdf
      dwg = GraphViz.new(:G, :type => :digraph)
      dwg.node[:fontname]  = "Helvetica"

      @activities.each do |_, activity|
        dwg.add_nodes(activity.to_s)
      end

      @activities.each do |_, activity|
        activity.predecessors.each do |predecessor|
          dwg.add_edges(predecessor.to_s, activity.to_s)
        end
      end

      dwg.output(:pdf => "#{name}.pdf")
    end
  end
end
