# frozen_string_literal: true

require 'date'

module CpmSolver
  # Modelled as Activity on Node (AON)
  class Activity
    attr_reader :reference, :name, :predecessors, :successors
    attr_accessor :duration, :early_start, :early_finish, :late_start, :late_finish

    def initialize(reference, name, duration)
      @reference = reference
      @name = name
      @duration = duration
      @predecessors = []
      @successors = []
    end

    def add_predecessor(predecessor)
      @predecessors << predecessor
    end

    def add_successor(successor)
      @successors << successor
    end

    def slack
      return unless @late_start && @early_start

      @slack ||= (@late_start - @early_start).to_i
    end

    def critical
      return unless @slack

      @slack.zero? ? true : false
    end

    def to_s
      "#{@reference} - #{@name}"
    end
  end
end
