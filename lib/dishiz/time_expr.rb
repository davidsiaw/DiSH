module Dishiz
  class TimeExpr
    PSMULT = {
      ns: 1000,
      us: 1000000,
      ms: 1000000000,
      s:  1000000000000,
    }
  
    def initialize(str)
      @str = str
    end
  
    def value
      @str.to_i
    end
  
    def unit
      @str.sub(value.to_s, '')
    end
  
    def ps
      value * PSMULT[unit.to_sym]
    end
  end
end
