module Dishiz
  class ComponentsDsl
    def initialize
      @types = {}
    end

    def com(name, *pins, &block)
      @types[name] = ComponentType.new(name, pins, &block)
    end

    def generate
      @types
    end
  end
end
