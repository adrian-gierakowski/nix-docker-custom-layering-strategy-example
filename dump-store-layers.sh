#!/usr/bin/env bash

conf_json_path=$(nix-store --query --references $(nix-build) | grep alerta-conf.json)

nix-shell -p jq --run "cat $conf_json_path | jq .store_layers > store-layers.json"
