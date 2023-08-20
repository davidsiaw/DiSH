require 'set'

simname = ARGV[0]

extensions = %w[
  init
  components
  net
]

extensions.each do |x|
  fname = "#{simname}.#{x}"
  next if File.exists?(fname)
  puts "'#{fname}' not found"
  exit(1)
end

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

class ComponentType
  attr_reader :name, :pin_array, :proc
  
  def initialize(name, pin_array, &block)
    @name = name
    @pin_array = pin_array
    @proc = block
  end
end

class Component
  attr_reader :name, :component_type, :options

  def initialize(name, component_type, options)
    @name = name
    @component_type = component_type
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

dsl = ComponentsDsl.new
dsl.instance_eval(File.read('components.rb'), 'components.rb')

component_types = dsl.generate

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

componentset = ComponentSet.new
lines = File.read("#{simname}.components").split("\n")
lines.each do |x|
  toks = x.split(' ')
  name = toks[0]
  type = toks[1]
  delay = toks[2]
  c = Component.new(name, component_types[type], {
    delay: TimeExpr.new(delay || '1ns').ps
  })

  componentset.add_component(name, c)
end

network = {}
lines = File.read("#{simname}.net").split("\n")
lines.each do |x|
  toks = x.split(' ')
  pin = toks[0]
  nodename = toks[1]

  network[nodename] ||= Node.new(nodename)
  network[nodename].add(pin)

  componentset.assign_pin(pin, nodename)
end

class SimulationStep
  attr_reader :platform

  def initialize(platform)
    @platform = platform
    @simlist = platform.componentset.components.map {|n, c| [n, false]}.to_h
    @proptimers = platform.network.keys.map {|x| [x, -1]}.to_h
    @nodes = platform.network.keys.map {|x| [x, 'f']}.to_h
    @nodedriver = platform.network.keys.map {|x| [x, false]}.to_h
  end

  def simulate(c, t=0)
    simset = {}
    output = platform.componentset.simulate(c, t, @nodes, platform.network)
    @simlist[c.name] = true

    output[:drive].each do |nodename, level|
      if @nodedriver[nodename] == false
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
      else
        raise "node #{nodename} driven by two components: #{c.name} #{@nodedriver[nodename]}"
      end

      puts "t=#{t} #{@nodedriver.to_a.flatten.join(' ')}"
    end

    output[:stack].each do |cname, t|
      simset[cname] = t
    end

    simset
  end
  
  def genstate
    SimulationState.new(self, 0, @nodes, @proptimers)
  end
end

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
      cname = simstack.shift

      c = componentset.components[cname]
      simstack += ss.simulate(c).map{|x| x[0]}

      break if simstack.length.zero?
    end

    ss.genstate
  end
end

class SimulationState
  attr_reader :platform, :pstime, :nodes, :proptimers
  def initialize(platform, pstime, nodes, proptimers)
    @platform = platform
    @pstime = pstime
    @nodes = nodes
    @proptimers = proptimers
  end
end


platform = SimulationPlatform.new(componentset, network)

is = platform.init_state
p is.nodes
# p componentset.single_lead_components
