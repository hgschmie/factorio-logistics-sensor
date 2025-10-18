# Logistics Sensor

Reports logistic requests for entities that participate in the logistics network to the circuit network.

* stationary entities: requester, provider, storage and buffer chests (and various mods that re-skin the chests such as [Warehousing](https://mods.factorio.com/mod/Warehousing), cargo landing pad, roboports, rocket silo, space platform hub
* mobile entities: cars, spidertron

Allows the selection of the logistics point for entities that have multiple logistics points (e.g. buffer or requester chests).

## Features

* GUI provides a preview of signals and supports selecting pickup, delivery and request signals
* GUI allows choosing between 1/0 or quantity for each signal. Signals can be inverted.
* can be rotated and moved (with [Even Pickier Dollies](https://mods.factorio.com/mod/even-pickier-dollies))
* supports blueprinting, cloning and settings copying
* debug mode shows scan area and connect/disconnect events

## Settings

### Update interval (Runtime, per Map)

Controls how often a sensor is updated. Default is every 10 ticks. Changing this value influences the amount of time the mod spends per tick.


### Entity scan interval (Runtime, per Map)

Controls how often the sensor looks for an entity to connect to. This is most important for sensors that should scan for mobile entities. Once it has connected, the scan interval changes: for mobile entities, it will scan every 30 ticks to see whether the mobile entity has moved away, for stationary entities it will scan every 300 ticks.

### Scan offset (Startup)

Controls the width of the scan area. The default is 0.2 tiles, so the scan area is 0.4 tiles wide.


### Scan range (Startup)

Controls the depth of the scan area. The default is 1.5 tiles.


## Contributing

I am not a graphics person. Best I can do is recoloring constant combinators. If you are as bored as I am and know how to use Blender well, I would be grateful for graphics contributions.

## Legal

(C) 2025 Henning Schmiedehausen (hgschmie). Released under the MIT License.
