# DiSHiZ

Digital Simulation with High-Z (read impedance)

## What is this

This program takes a graph and time period and generates a simulation of digital circuits that include high impedance behavior.

## Files needed for simulation

`<simname>.components` - Components description
`<simname>.net` - Network description
`<simname>.init` - Initial state description

`sim <simname> <amount of time = 1s>`

## File format of components

each line instantiates a component from its component type

```
<component name> <component type> <prop delay = 1ns>
```

## File format of net

```
<component pin> <node name>
```

Component pin name is `<component name>_<pin name>`

## Built in component types

- `VCC` - pins `A` - constant high
- `GND` - pins `A` - constant low
- `CLK` - pins `A` - clock with period delay
- `STEP` - pins `A` - step from 0 to 1 at delay

- `BUF` - pins `A` `Y` - buffer
- `NOT` - pins `A` `Y` - logic not
- `AND` - pins `A` `B` `Y` - logic and
- `OR` - pins `A` `B` `Y` - logic or
- `XOR` - pins `A` `B` `Y` - logic xor
- `NOR` - pins `A` `B` `Y` - logic nor
- `NAND` - pins `A` `B` `Y` - logic nand
- `MUX` - pins `A` `B` `S` `Y` - multiplexer S0: Y = A ; S1: Y = B

- `DFF` - pins `D` `C` `Q` - d flipflop (init state Q = x)

- `TRI` - pins `A` `E` `Y` - tristate buffer E0: Y = z ; E1 Y = A
- `RES` - pins `A` `B` - resistor
