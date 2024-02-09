#!/usr/bin/env sh

set -x

tflocal init; tflocal plan; tflocal apply --auto-approve

ws_endpoint=$(tflocal output -json | jq -r .ws_endpoint.value)

wscat -c 127.0.0.1:4510
