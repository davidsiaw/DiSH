# frozen_string_literal: true

# `VCC` - pins `A` - constant high
com 'VCC', 'A' do |_options, _pins, _time, _state, out|
  out['A'] = true
end

# `GND` - pins `A` - constant low
com 'GND', 'A' do |_options, _pins, _time, _state, out|
  out['A'] = false
end

# `CLK` - pins `A` - clock with period delay
com 'CLK', 'A' do |options, _pins, time, _state, out|
  fullwave = options[:delay]
  halfwave = delay / 2
  section_of_period = time % fullwave
  out['A'] = section_of_period > halfwave

  out[:next] = ((time / halfwave) * (halfwave + 1))
end

# `STEP` - pins `A` - step from 0 to 1 at delay
com 'STEP', 'A' do |options, _pins, time, _state, out|
  delay = options[:delay]
  if time > delay
    out['A'] = true
  else
    out['A'] = false
    out[:next] = delay
  end
end

# `BUF` - pins `A` `Y` - buffer
com 'BUF', 'A', 'Y' do |_options, pins, _time, _state, out|
  out['Y'] = if !pins['A'].nil? != pins['A']
               :unknown
             else
               pins['A']
             end
end

# `NOT` - pins `A` `Y` - logic not
com 'NOT', 'A', 'Y' do |_options, pins, _time, _state, out|
  out['Y'] = if !pins['A'].nil? != pins['A']
               :unknown
             else
               !pins['A']
             end
end

# `AND` - pins `A` `B` `Y` - logic and
com 'AND', 'A', 'B', 'Y' do |_options, pins, _time, _state, out|
  out['Y'] = if !pins['A'].nil? != pins['A'] || !pins['B'].nil? != pins['B']
               :unknown
             else
               pins['A'] && pins['B']
             end
end

# `OR` - pins `A` `B` `Y` - logic or
com 'OR', 'A', 'B', 'Y' do |_options, pins, _time, _state, out|
  out['Y'] = if !pins['A'].nil? != pins['A'] || !pins['B'].nil? != pins['B']
               :unknown
             else
               pins['A'] || pins['B']
             end
end

# `XOR` - pins `A` `B` `Y` - logic xor
com 'XOR', 'A', 'B', 'Y' do |_options, pins, _time, _state, out|
  out['Y'] = if !pins['A'].nil? != pins['A'] || !pins['B'].nil? != pins['B']
               :unknown
             else
               pins['A'] ^ pins['B']
             end
end

# `NOR` - pins `A` `B` `Y` - logic nor
com 'NOR', 'A', 'B', 'Y' do |_options, pins, _time, _state, out|
  out['Y'] = if !pins['A'].nil? != pins['A'] || !pins['B'].nil? != pins['B']
               :unknown
             else
               !(pins['A'] || pins['B'])
             end
end

# `NAND` - pins `A` `B` `Y` - logic nand
com 'NAND', 'A', 'B', 'Y' do |_options, pins, _time, _state, out|
  out['Y'] = if !pins['A'].nil? != pins['A'] || !pins['B'].nil? != pins['B']
               :unknown
             else
               !(pins['A'] && pins['B'])
             end
end

# `MUX` - pins `A` `B` `S` `Y` - multiplexer S0: Y = A ; S1: Y = B
com 'MUX', 'A', 'B', 'S', 'Y' do |_options, pins, _time, _state, out|
  out['Y'] = if !pins['S'].nil? != pins['S']
               :unknown
             elsif pins['S'] == false
               pins['A']
             else
               pins['B']
             end
end

# `DFF` - pins `D` `C` `Q` - d flipflop (init state Q = x)
com 'DFF', 'D', 'C', 'Q' do |options, pins, time, state, out|
  options[:setup_time] = 1000 if options[:setup_time].nil?
  state[:q] = :unknown if state[:q].nil?

  if !state[:tick_t].nil? && !state[:setup_t].nil? && (time == state[:tick_t] + options[:delay])
    # if it is the hold time check that setup time is still valid
    # if not setup time the output x
    state[:q] = if state[:tick_t] - state[:setup_t] > options[:setup_time]
                  :unknown
                else
                  state[:in_data]
                end
    state[:tick_t] = nil
    state[:setup_t] = nil
  elsif state[:prev_c].nil?
    state[:prev_c] = pins['C']
  else
    # positive clock edge
    if state[:prev_c] == false && pins['C'] == true
      state[:tick_t] = time
      out[:next] = time + options[:delay]
    elsif state[:in_data] != pins['D']
      # update setup time upon data change
      state[:in_data] = pins['D']
      state[:setup_t] = time
    end

    state[:prev_c] = pins['C']
  end

  out['Q'] = state[:q]
end

# `TRI` - pins `A` `E` `Y` - tristate buffer E0: Y = z ; E1 Y = A
com 'TRI', 'A', 'E', 'Y' do |_options, pins, _time, _state, out|
  out['Y'] = if !pins['E'].nil? != pins['E']
               :unknown
             elsif pins['E'] == false
               :float
             else
               pins['A']
             end
end

# `RES` - pins `A` `B` - resistor
com 'RES', 'A', 'B' do |_options, pins, _time, _state, out|
  if pins['A'] != :float && pins['B'] != :float
    out['A'] = pins['A']
  elsif pins['B'] != :float && pins['A'] != :float
    out['B'] = pins['B']
  end
end
