# Shared Makefile logic for the LocalStack Terraform samples.
#
# Include it from a sample directory:
#
#     include ../common.mk
#
# Customise a sample by setting any of these variables BEFORE the include:
#   TEST_CMD      - command run by the `test` target          (default: ./run.sh)
#   INIT_CMD      - command run by the `init` target          (default: lstk terraform init)
#   DEPLOY_CMD    - command run by the `deploy` target        (default: lstk terraform apply)
#   INSTALL_EXTRA - extra command run by the `install` target (default: check for terraform)
#   DEPLOY_STEPS  - targets chained by `run` and `test-ci`     (default: start install init deploy test)
#
# Use `=` (deferred) for any value that references $(LSTK) or $(PYTHON_BIN),
# since those are defined below, after the point the sample sets its overrides.

export AWS_ACCESS_KEY_ID ?= test
export AWS_SECRET_ACCESS_KEY ?= test
export AWS_DEFAULT_REGION ?= us-east-1
SHELL := /bin/bash
PYTHON_BIN ?= $(shell which python3 || which python)
LSTK := lstk --non-interactive

TEST_CMD ?= ./run.sh
INIT_CMD ?= $(LSTK) terraform init
DEPLOY_CMD ?= $(LSTK) terraform apply --auto-approve
INSTALL_EXTRA ?= @which terraform || (echo 'Terraform was not found';)
DEPLOY_STEPS ?= start install init deploy test

usage:       ## Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

start:       ## Start LocalStack
	@test -n "${LOCALSTACK_AUTH_TOKEN}" || (echo "LOCALSTACK_AUTH_TOKEN is not set" && exit 1);
	LOCALSTACK_DEBUG=1 LOCALSTACK_AUTH_TOKEN=$(LOCALSTACK_AUTH_TOKEN) $(LSTK) start
	$(LSTK) setup aws --force

stop:        ## Stop LocalStack
	$(LSTK) stop

logs:        ## Write the LocalStack logs to logs.txt
	@$(LSTK) logs > logs.txt

install:     ## Install dependencies
	@which lstk || brew install localstack/tap/lstk
	$(INSTALL_EXTRA)

init:        ## Initialize Terraform
	$(INIT_CMD)

deploy:      ## Deploy the sample
	$(DEPLOY_CMD)

test:        ## Run the sample smoke test
	$(TEST_CMD)

run: $(DEPLOY_STEPS)

test-ci:
	make $(DEPLOY_STEPS); return_code=`echo $$?`;\
	make logs; make stop; exit $$return_code;

clean:       ## Remove Terraform state
	rm -rf .terraform

.PHONY: usage start stop logs install init deploy test run test-ci clean
