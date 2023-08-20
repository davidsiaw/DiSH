# frozen_string_literal: true

module Dishiz
  class SimulationState
    attr_reader :platform, :pstime, :nodes, :proptimers

    def initialize(platform, pstime, nodes, proptimers)
      @platform = platform
      @pstime = pstime
      @nodes = nodes
      @proptimers = proptimers
    end

    def to_s
      puts "t=#{pstime} #{@nodes.to_a.map { |x, y| [x, state_to_s(y)] }.flatten.join(' ')}"
    end

    def state_to_s(y)
      case y
      when false
        0
      when true
        1
      when :float
        'f'
      when :unknown
        'x'
      end
    end
  end
end
