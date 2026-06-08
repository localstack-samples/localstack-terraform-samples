#!/usr/bin/env sh

set -x

lstk tf init; lstk tf plan; lstk tf apply --auto-approve

ws_endpoint=$(lstk tf output -json | jq -r .ws_endpoint.value)

wscat -c 127.0.0.1:4510
