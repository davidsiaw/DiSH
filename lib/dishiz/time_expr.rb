# frozen_string_literal: true

module Dishiz
  class TimeExpr
    PSMULT = {
      ns: 1000,
      us: 1_000_000,
      ms: 1_000_000_000,
      s: 1_000_000_000_000
    }.freeze

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
