module Dishiz
  class SimulationPlatform
    attr_reader :componentset, :network
    def initialize(componentset, network)
      @componentset = componentset
      @network = network
    end

    def init_state
      puts "calc init"
      ss = SimulationStep.new(self)

      simset = Set.new
      componentset.single_lead_components.each do |c|
        simset += ss.simulate(c).map{|x| x[0]}
      end

      simstack = simset.to_a

      loop do
        break if simstack.length.zero?
        
        cname = simstack.shift

        c = componentset.components[cname]
        simstack += ss.simulate(c).map{|x| x[0]}

      end

      ss.genstate
    end
  end
end
