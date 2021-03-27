# swim-maps

Makefile helps collect and parse GIS data for a few maps,
specifically places where I swim.

To see some of the maps in action, check out [my swim blog][blog].

## Generating the maps

```
make maps
```

This will download and generate all the maps tracked by this project,
and place them in the `maps` directory.

## Requirements

- A current-ish version of `yarn` or `npm` (and `node`).
- `unzip`

## Directories

- `maps` this is the output directory

- `_maps` this is the working directory, intermediate files are downloaded and
  unzipped here

- `_src` source maps that I can't figure out current public links for these,
  the various links tend to drift over time
