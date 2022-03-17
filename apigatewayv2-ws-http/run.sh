#!/usr/bin/env sh

terraform init; terraform plan; terraform apply --auto-approve

wscat -c localhost:4510
