export AWS_ACCESS_KEY_ID ?= test
export AWS_SECRET_ACCESS_KEY ?= test
export AWS_DEFAULT_REGION = us-east-1
SHELL := /bin/bash
PYTHON_BIN ?= $(shell which python3 || which python)

usage:       ## Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

start:
	localstack start -d

stop:
	localstack stop

ready:
	@echo Waiting on the LocalStack container...
	@localstack wait -t 30 && echo Localstack is ready to use! || (echo Gave up waiting on LocalStack, exiting. && exit 1)

logs:
	@localstack logs > logs.txt

install:    ## Install dependencies
	@which localstack || pip install localstack
	@which awslocal || pip install awscli-local
	@which terraform || (echo 'Terraform was not found';)
	@which tflocal || pip install terraform-local

init:
	tflocal init

deploy:
	tflocal apply --auto-approve

run: start install init deploy

test-ci:
	make start install init deploy; return_code=`echo $$?`;\
	make logs; make stop; exit $$return_code;

clean:
	rm -rf .terraform

.PHONY: start ready install init deploy test logs run test-ci clean