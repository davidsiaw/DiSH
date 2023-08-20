# frozen_string_literal: true

module Dishiz
  class Node
    attr_reader :name, :pins

    def initialize(name)
      @name = name
      @pins = []
    end

    def add(pin)
      @pins << pin
    end
  end
end
