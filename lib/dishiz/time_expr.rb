# frozen_string_literal: true

class Symbol
  def bool?
    false
  end

  def driven?
    self == :undet
  end
end

class TrueClass
  def bool?
    true
  end

  def driven?
    true
  end
end

class FalseClass
  def bool?
    true
  end

  def driven?
    true
  end
end

module Dishiz
  class TimeExpr
    PSMULT = {
      ps: 1,
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
      raise "'#{@str}' has no valid unit! valid are #{PSMULT.keys}" if PSMULT[unit.to_sym].nil?
      value * PSMULT[unit.to_sym]
    end
  end

  class IoDefs
    def src
      {
        inputs: [],
        outputs: %w[Y]
      }
    end

    def buf
      {
        inputs: %w[A],
        outputs: %w[Y]
      }
    end

    def not
      {
        inputs: %w[A],
        outputs: %w[Y]
      }
    end

    def bin
      {
        inputs: %w[A B],
        outputs: %w[Y]
      }
    end

    def tri
      {
        inputs: %w[E A],
        outputs: %w[Y]
      }
    end

    def res
      {
        inputs: %w[A B],
        outputs: []
      }
    end
  end

  class Component
    attr_reader :state
    def initialize(cmdstring)
      @cmdstring = cmdstring
      @state = {}
    end

    def toks
      @toks ||= @cmdstring.split(' ')
    end

    def type
      toks[0]
    end

    def name
      toks[1]
    end

    def cmdlist
      toks[2..-1]
    end

    def input_names
      IoDefs.new.send(type.downcase.to_sym)[:inputs]
    end

    def outputs
      IoDefs.new.send(type.downcase.to_sym)[:outputs].map do |x|
        Node.new(self, x)
      end
    end

    def inspect
      "<#{@cmdstring}>"
    end

    def hash
      @cmdstring.hash
    end
  end

  class SourceOp
    attr_reader :time, :value
    def initialize(time, value)
      @time = time
      @value = value
    end

    def type
      if @time == 'loop'
        :loop
      elsif @time.is_a?(Integer)
        :time
      else
        raise "Unknown source operation #{@time} #{@value}"
      end
    end

    def inspect
      case type
      when :loop
        return "<op repeat>"
      when :time
        return "<op t=#{@time} v=#{@value}>"
      end
    end
  end

  class SourceComponent < Component
    def source_program
      @source_program ||= begin
        arr = cmdlist[1..-1]
        ops = []
        loop do
          break if arr.first.nil?
    
          time = arr.shift
          value = arr.shift
          break if time == 'loop'
          op = SourceOp.new(TimeExpr.new(time).ps, value)
          ops << op
        end
        ops
      end
    end

    def loop?
      cmdlist.last == 'loop'
    end

    def next_trig_at(time)
      adjust = 0
      if loop?
        ntime = time % source_program.last.time
        adjust = (time / source_program.last.time) * source_program.last.time
        time = ntime
      end
      source_program.each do |op|
        return (op.time + adjust) if op.time > time
      end
      nil
    end

    def value_at_time(time)

      if loop?
        time = time % source_program.last.time
      end

      last = MNE_TO_VALUE[cmdlist[0]]
      source_program.each do |op|
        break if op.time > time
        last = MNE_TO_VALUE[op.value]
      end

      last
    end
  end

  class Node
    attr_reader :component, :pinname
    def initialize(component, pinname)
      @component = component
      @pinname = pinname
    end

    def name
      "#{@component.name}_#{@pinname}"
    end

    def to_s
      name
    end
  end

  class Connection
    def initialize(cmdstring)
      @cmdstring = cmdstring
    end

    def toks
      @toks ||= @cmdstring.split(' ')
    end

    def from_nodename
      "#{from_name}_#{from_pin}"
    end

    def to_name
      toks[0]
    end

    def to_pin
      toks[1]
    end

    def from_name
      toks[2]
    end

    def from_pin
      toks[3]
    end

    def to_s
      "#{to_name}_#{to_pin}"
    end
  end

  class Executable
    def initialize
      @name = ARGV[0]
      if @name.nil?
        puts 'USAGE: dishiz <name> <time = 10ns>'
        exit(1)
      end
    end
    
    def componentlist
      @componentlist ||= File.read("#{@name}.list").split("\n")
    end

    def netlist
      @netlist ||= File.read("#{@name}.net").split("\n")
    end
    
    def components
      @components ||= componentlist.map do |x|
        if x.start_with?('SRC')
          SourceComponent.new(x)

        else
          Component.new(x)
        end
      end
    end

    def connections
      @connections ||= netlist.map {|x| Connection.new(x)}
    end

    def network
      @network ||= Network.new(components, connections)
    end
  end

  class Network
    def initialize(components, connections)
      @components = components
      @connections = connections
    end

    def nodes
      @nodes ||= @components.flat_map {|x| x.outputs}
    end

    def src_nodes
      nodes.select {|x| x.component.type == 'SRC'}
    end

    def resistors
      @components.select {|comp| comp.type == 'RES'}
    end

    def node_hash
      @node_hash ||= nodes.map {|node| [node.name, node]}.to_h
    end

    def component_hash
      @component_hash ||= @components.map {|comp| [comp.name, comp]}.to_h
    end

    def fanout
      @fanout ||= nodes.map do |node|
        [node.name, @connections.select{|x| x.from_nodename == node.name}]
      end.to_h
    end

    def fanin
      @fanin ||= begin
        result = {}
        fanout.each do |k,v|
          v.each do |con|
            result["#{con.to_name}_#{con.to_pin}"] = node_hash[k]
          end
        end
        result
      end
    end

    def node_at(comp, pinname)
      fanin["#{comp.name}_#{pinname}"]
    end
  end


  MNE_TO_VALUE = {
    '0' => false,
    '1' => true,
    'Z' => :float,
    'z' => :float,
    'F' => :float,
    'f' => :float,
    'X' => :undet,
    'x' => :undet
  }

  VALUE_TO_MNE = MNE_TO_VALUE.map {|k,v| [v,k]}.to_h

  class BinFunctions

    def nonbool?(a, b)
      !a.bool? || !b.bool?
    end

    def and(a, b)
      return false if a == false || b == false
      return :undet if nonbool?(a, b)

      a && b
    end

    def or(a, b)
      return true if a == true || b == true
      return :undet if nonbool?(a, b)

      a || b
    end

    def xor(a, b)
      return :undet if nonbool?(a, b)

      a ^ b
    end

    def nand(a, b)
      return true if a == false || b == false
      return :undet if nonbool?(a, b)

      !(a && b)
    end

    def nor(a, b)
      return false if a == true || b == true
      return :undet if nonbool?(a, b)

      !(a || b)
    end

    def tri(a, b)
      return :undet if nonbool?(a, b)
      return :float if !b
      
      a 
    end
  end

  class NetStateDisplayer
    def initialize(network)
      @network = network
    end

    def nodename_len_list
      res = {}
      @network.nodes.each do |x|
        res[x.name] = x.name.length + 1
      end
      res
    end

    def display(simstate)
      str = simstate.time.to_s.rjust(10, ' ') + ' '
      nodename_len_list.each do |k, v|
        mne = VALUE_TO_MNE[simstate.state[k]]
        str += mne.ljust(v, ' ')
      end
      str
    end

    def display_keys
      str = 'time'.rjust(10, ' ') + ' '
      nodename_len_list.each do |k, v|
        str += k.ljust(v, ' ')
      end
      str
    end
  end

  class SimState
    attr_reader :network, :time, :state
    def initialize(network, state = nil, time = 0)
      @network = network
      @time = time
      @state = state
    end

    def state
      @state ||= network.nodes.map {|x| [x.name, :float]}.to_h
    end

    def to_s
      NetStateDisplayer.new(@network).display(self)
    end
  end

  class SimStep
    attr_reader :futurelist, :time
    def initialize(network, prevstep = nil)
      @network = network
      @prevstep = prevstep
      @time = prevstep&.futurelist&.keys&.min || 0
      @futurelist = prevstep&.futurelist || {}
    end

    def simstate
      #p " B #{@time} #{self}"
      @simstate ||= SimState.new(@network, @prevstep&.simstate&.state&.clone, @time)
    end

    def write(node, drive)
      simstate.state[node.name] = drive
    end

    def read(node)
      simstate.state[node.name]
    end

    def run_component(comp, inputs)
      case(comp.type)
        when 'SRC'
          return { Y: comp.value_at_time(@time), next_trig: comp.next_trig_at(@time) }
        when 'BIN'
          op = comp.cmdlist.first.downcase.to_sym
          return { Y: BinFunctions.new.send(op, inputs[:A], inputs[:B]) }
        when 'BUF'
          if comp.state[:last_input].nil?
            comp.state[:last_input] = inputs[:A]
            comp.state[:input_level] = inputs[:A]
            comp.state[:input_time] = @time
          end

          delay = TimeExpr.new(comp.cmdlist[1] || '1ns').ps

          last = comp.state[:last_input]
          
          if inputs[:A] != comp.state[:input_level]
            comp.state[:input_level] = inputs[:A]
            comp.state[:input_time] = @time
            if comp.cmdlist[0] == 'HOLD' && comp.state[:input_start].nil?
              comp.state[:input_start] = @time
            end
            return { Y: last, next_trig: @time + delay }
          end
          
          if @time - comp.state[:input_time] >= delay
            comp.state[:last_input] = comp.state[:input_level]
            return { Y: comp.state[:last_input] }
          end

          if comp.cmdlist[0] == 'HOLD' &&
              !comp.state[:input_start].nil? &&
              @time - comp.state[:input_start] >= delay
            return { Y: :undet }
          end

          return { Y: last }
      end
      raise "unknown component #{comp.type}"
    end

    def do_components(comps)
      new_comps_todo = Set.new
      comps.each do |comp|
        next if comp.type == 'RES'

        inputs = {}
        comp.input_names.each do |pinname|
          inputs[pinname.to_sym] = read(@network.node_at(comp, pinname))
        end

        # p inputs

        outputs = run_component(comp, inputs)

        if !outputs[:next_trig].nil?
          @futurelist[outputs[:next_trig]] ||= Set.new
          @futurelist[outputs[:next_trig]] << comp.name
        end
        
        nodes = comp.outputs
        nodes.each do |node|
          write(node, outputs[node.pinname.to_sym])
          new_comps_todo += @network.fanout[node.name].map do |x|
            @network.component_hash[x.to_name]
          end
        end
      end
      new_comps_todo
    end

    def do_resistors
      new_comps_todo = Set.new
      @network.resistors.each do |resistor|
        node_a = @network.node_at(resistor, 'A')
        node_b = @network.node_at(resistor, 'B')
        a = read(node_a)
        b = read(node_b)

        if a == :float && b.driven?
          write(node_a, b)
          new_comps_todo += @network.fanout[node_a.name].map do |x|
            @network.component_hash[x.to_name]
          end
        elsif a.driven? && b == :float
          write(node_b, a)
          new_comps_todo += @network.fanout[node_b.name].map do |x|
            @network.component_hash[x.to_name]
          end
        end
      end

      new_comps_todo
    end

    def calc!
      comps_to_do = Set.new

      if @prevstep != nil
        @futurelist[@time].each do |compname|
          comps_to_do << @network.component_hash[compname]
        end
        @futurelist.delete(@time)
      else
        @network.src_nodes.each do |node|
          comps_to_do << node.component
        end
      end
      
      loop do
        prev = simstate.to_s
        if comps_to_do.empty?
          comps_to_do = do_resistors

          break if comps_to_do.empty?
        end

        comps_to_do = do_components(comps_to_do)

        break if simstate.to_s == prev
      end
    end
  end

end
