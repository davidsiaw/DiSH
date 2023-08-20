# frozen_string_literal: true

require 'singleton'

module Dishiz
  class ComponentTypelib
    include Singleton

    def initialize
      filename = File.join(Gem.loaded_specs['dishiz'].full_gem_path, 'data', 'dishiz', 'components.rb')

      dsl = ComponentsDsl.new
      dsl.instance_eval(File.read(filename), filename)

      @component_types = dsl.generate
    end

    def find(typename)
      @component_types[typename]
    end
  end
end
