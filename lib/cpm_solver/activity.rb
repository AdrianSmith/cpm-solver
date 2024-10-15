require "date"

module CpmSolver
  class Activity
    attr_reader :reference, :name
    attr_reader :predecessors, :successors
    attr_accessor :duration, :slack
    attr_accessor :early_start, :early_finish
    attr_accessor :late_start, :late_finish

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
      if @late_start && @early_start
        @slack ||= (@late_start - @early_start).to_i
      else
        nil
      end
    end

    def critical
      if @slack
        @slack == 0 ? true : false
      else
        nil
      end
    end

    def to_s
      "#{@reference} - #{@name}"
    end
  end
end
