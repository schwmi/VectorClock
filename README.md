# VectorClock

A VectorClock implementation, supporting total ordering by using unix timestamp + actorID for breaking ties.
Clocks are implemented as non-mutable struct, incrementing and merging always returns a new clock.

## Usage

### Create a new clock

```
let clock = VectorClock(actorID: "A")
```

### Incrementing a clock

```
let incrementedClock = clock.incrementing("B")
```

### Merging two clocks

```
let clockA = VectorClock(actorID: "A")
let clockB = VectorClock(actorID: "B")
let mergedClock = clockA.merging(clockB)
```

### Comparing clocks

#### For total order

```
let clockA = VectorClock(actorID: "A")
let clockB = VectorClock(actorID: "B")
let isAscending = clockA < clockB // true
```

#### Partial order

```
let clockA = VectorClock(actorID: "A")
let clockB = VectorClock(actorID: "B")
let partialOrder = clockA.partialOrder(other: clockB) // .concurrent
```
