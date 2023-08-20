module Dishiz
  class ComponentType
    attr_reader :name, :pin_array, :proc
    
    def initialize(name, pin_array, &block)
      @name = name
      @pin_array = pin_array
      @proc = block
    end
  end
end
