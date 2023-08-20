module Dishiz
  class Component
    attr_reader :name, :component_type, :options

    def initialize(name, component_typename, options)
      @name = name
      @component_type = ComponentTypelib.instance.find(component_typename)
      @options = options
      @state = {}
    end

    def delay
      @options[:delay]
    end

    def pin_list
      component_type.pin_array.map do |pin|
        "#{name}_#{pin}"
      end
    end

    def simulate(pins, time)
      out = {}
      component_type.proc.call(@options, pins, time, @state, out)
      out
    end
  end
end
