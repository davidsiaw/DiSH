# DiSHiZ

Digital Simulation with High-Z (read impedance)

## What is this

This program takes a graph and time period and generates a simulation of digital circuits that include high impedance behavior.

## Files needed for simulation

`<simname>.list` - Components description
`<simname>.net` - Network description

`dishiz <simname> <amount of time = 1ns>`

## File format of components

each line instantiates a component. There are 3 component types:

- SRC
- BIN
- BUF
- RES

### Format For SRC components

```
SRC <name> <logic level> <program...>
```

Example of a constant voltage source

```
SRC vcc 1
```

Example of a step voltage source (goes from 0 to 1 at t=2ns)

```
SRC step 0 2ns 1
```

### Format for BIN components

```
BIN <name> <type>
```

Example:

```
BIN and AND
```

Types available:
- AND
- OR
- XOR
- NAND
- NOR
- TRI (A is input and B is enable)

### Format for BUF components

Buf components introduce piecewise delays into the circuit.

There is a HOLD type and a TRIG type. HOLD goes to undetermined drive until the input stabilizes for the duration of the delay, TRIG simply stays at its previous input and then propagates a stable input without going undetermined.

```
BUF <name> <type> <delay = 1ns>
```

Example

```
BUF buf TRIG 2ns
```

## Format of RES components

Resistors are there to pull up or pull down a node if their impedance goes high or low

```
RES <name>
```

Example

```
RES res1
```

Typical usage: (pull up resistor)

```
res1 A vcc Y
res2 A tri Y
```

## File format of net

.net files are structured in such a way that an input can only appear once on the left side.

```
<input component> <input component pin> <output component name> <output component pin>
```

Example (Feeds a high source to both pins of the and gate)

```
and A vcc Y
and B vcc Y
```

# How simulation happens

- Every component output is a node
- Each node can have one of 4 values:
  - float
  - undetermined (driven but could be 1 or 0)
  - logic 1
  - logic 0
- when a component output value changes the next component is notified of the change
- only TRI can output float
- only BUF can create delays
- sources can be programmed to have a particular output pattern
