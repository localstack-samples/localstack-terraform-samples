#!/usr/bin/env sh

rm terraform.tfstate* || true

lstk tf init; lstk tf plan; lstk tf apply --auto-approve

wscat -c localhost:4510 -H HeaderAuth1:headerValue1
