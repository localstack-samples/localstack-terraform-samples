#!/usr/bin/env sh

tflocal init; tflocal apply -auto-approve

wscat -c localhost:4510
