# frozen_string_literal: true

module Dishiz
  class SimulationStep
    attr_reader :platform

    def initialize(platform)
      @platform = platform
      @simlist = platform.componentset.components.map { |n, _c| [n, false] }.to_h
      @proptimers = platform.network.keys.map { |x| [x, -1] }.to_h
      @nodes = platform.network.keys.map { |x| [x, :float] }.to_h
      @nodedriver = platform.network.keys.map { |x| [x, false] }.to_h
    end

    def simulate(c, t = 0)
      simset = {}
      output = platform.componentset.simulate(c, t, @nodes, platform.network)
      @simlist[c.name] = true

      output[:drive].each do |nodename, level|
        unless @nodedriver[nodename] == false
          raise "node #{nodename} driven by two components: #{c.name} #{@nodedriver[nodename]}"
        end

        @nodes[nodename] = level
        @nodedriver[nodename] = c.name

        platform.network[nodename].pins.each do |pin|
          toks = pin.split('_')
          cname = toks[0]
          if @simlist[cname] == false
            c = platform.componentset.components[cname]
            simset[c.name] = c.delay + t
          end
        end

        # puts "t=#{t} #{@nodedriver.to_a.flatten.join(' ')}"
      end

      output[:stack].each do |cname, time|
        simset[cname] = time
      end

      simset
    end

    def genstate
      SimulationState.new(self, 0, @nodes, @proptimers)
    end
  end
end
