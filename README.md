# Nix custom docker layering strategy

Demonstration of how a custom layeringPipeline can be used to optimise
docker layers for faster image rebuilds given a python application.

See [store-layers.json](/store-layers.json) for how nix packages have been
grouped into layers.
