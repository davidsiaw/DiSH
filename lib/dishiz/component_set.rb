module Dishiz
  class ComponentSet
    attr_reader :components, :pins
    def initialize
      @components = {}
      @pins = {}
    end

    def simulate(c, time, nodes, network)
      pins = {}
      res = {
        drive: [],
        stack: []
      }
      
      c.pin_list.each do |pin|
        # quit quickly if we discover a component thats not fully connected
        return res if @pins[pin] == false

        toks = pin.split('_')
        pins[toks[1]] = nodes[@pins[pin]]
      end

      out = c.simulate(pins, time)

      out.each do |k, v|
        if k == :next
          res[:stack] << [c.name, v]
        else
          res[:drive] << [@pins["#{c.name}_#{k}"],  v]
        end
      end
      res
    end

    def single_lead_components
      @single_lead_components ||= begin
        results = []
        @components.each do |name, c|
          next if c.component_type.pin_array.length != 1

          results << c
        end
        results
      end
    end

    def add_component(name, c)
      @components[name] = c
      c.pin_list.each do |pin|
        @pins[pin] = false
      end
    end

    def assign_pin(pin, node)
      if pins[pin] != false
        raise "pin #{pin} connected to two nodes!"
      end
      pins[pin] = node
    end
  end
end
