#!/usr/bin/env sh

rm terraform.tfstate* || true

tflocal init; tflocal plan; tflocal apply --auto-approve

wscat -c localhost:4510 -H HeaderAuth1:headerValue1
