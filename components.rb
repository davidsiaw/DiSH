# `VCC` - pins `A` - constant high
com 'VCC', 'A' do |options, pins, time, state, out|
  out['A'] = 1
end

# `GND` - pins `A` - constant low
com 'GND', 'A' do |options, pins, time, state, out|
  out['A'] = 0
end

# `CLK` - pins `A` - clock with period delay
com 'CLK', 'A' do |options, pins, time, state, out|
  fullwave = options[:delay]
  halfwave = delay / 2
  section_of_period = time % fullwave
  if section_of_period > halfwave
    out['A'] = 1
  else
    out['A'] = 0
  end

  out[:next] = ((time / halfwave) * (halfwave + 1))
end

# `STEP` - pins `A` - step from 0 to 1 at delay
com 'STEP', 'A' do |options, pins, time, state, out|
  delay = options[:delay]
  if time > delay
    out['A'] = 1
  else
    out['A'] = 0
    out[:next] = delay
  end
end

# `BUF` - pins `A` `Y` - buffer
com 'BUF', 'A', 'Y' do |options, pins, time, state, out|
  if (pins['A'] != 1 && pins['A'] != 0)
    out['Y'] = 'x'
  else
    out['Y'] = pins['A']
  end
end

# `NOT` - pins `A` `Y` - logic not
com 'NOT', 'A', 'Y' do |options, pins, time, state, out|
  if (pins['A'] != 1 && pins['A'] != 0)
    out['Y'] = 'x'
  else
    out['Y'] = (pins['A'] == 1) ? 0 : 1
  end
end

# `AND` - pins `A` `B` `Y` - logic and
com 'AND', 'A', 'B', 'Y' do |options, pins, time, state, out|
  if (pins['A'] != 1 && pins['A'] != 0) || (pins['B'] != 1 && pins['B'] != 0)
    out['Y'] = 'x'
  else
    out['Y'] = (pins['A'] == 1 && pins['B'] == 1) ? 1 : 0
  end
end

# `OR` - pins `A` `B` `Y` - logic or
com 'OR', 'A', 'B', 'Y' do |options, pins, time, state, out|
  if (pins['A'] != 1 && pins['A'] != 0) || (pins['B'] != 1 && pins['B'] != 0)
    out['Y'] = 'x'
  else
    out['Y'] = (pins['A'] == 1 || pins['B'] == 1) ? 1 : 0
  end
end

# `XOR` - pins `A` `B` `Y` - logic xor
com 'XOR', 'A', 'B', 'Y'

# `NOR` - pins `A` `B` `Y` - logic nor
com 'NOR', 'A', 'B', 'Y' do |options, pins, time, state, out|
  if (pins['A'] != 1 && pins['A'] != 0) || (pins['B'] != 1 && pins['B'] != 0)
    out['Y'] = 'x'
  else
    out['Y'] = (pins['A'] == 1 || pins['B'] == 1) ? 0 : 1
  end
end

# `NAND` - pins `A` `B` `Y` - logic nand
com 'NAND', 'A', 'B', 'Y' do |options, pins, time, state, out|
  if (pins['A'] != 1 && pins['A'] != 0) || (pins['B'] != 1 && pins['B'] != 0)
    out['Y'] = 'x'
  else
    out['Y'] = (pins['A'] == 1 && pins['B'] == 1) ? 0 : 1
  end
end

# `MUX` - pins `A` `B` `S` `Y` - multiplexer S0: Y = A ; S1: Y = B
com 'MUX', 'A', 'B', 'S', 'Y'

# `DFF` - pins `D` `C` `Q` - d flipflop (init state Q = x)
com 'DFF', 'D', 'C', 'Q'

# `TRI` - pins `A` `E` `Y` - tristate buffer E0: Y = z ; E1 Y = A
com 'TRI', 'A', 'E', 'Y'

# `RES` - pins `A` `B` - resistor
com 'RES', 'A', 'B'
