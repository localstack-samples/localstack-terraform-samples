#!/usr/bin/env sh

lstk tf init; lstk tf apply -auto-approve

wscat -c localhost:4510
