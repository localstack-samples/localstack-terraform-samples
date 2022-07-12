#!/usr/bin/env sh

rm terraform.tfstate* || true

terraform init; terraform plan; terraform apply --auto-approve

wscat -c localhost:4510 -H HeaderAuth1:headerValue1
