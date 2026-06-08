LSTK := lstk --non-interactive

usage:         ## Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

install:       ## Install dependencies for all projects
	MAKE_TARGET='install' make for-each-dir

lint:          ## Run code linter for all projects (skips sample-archive)
	@echo "==> Linting terraform code"
	@find . -name '*.tf' -not -path './sample-archive/*' -exec dirname {} \; | sort -u | xargs -I{} terraform fmt -diff=true -write=true {}

start:         ## Start LocalStack infrastructure
	$(LSTK) start

stop:          ## Stop LocalStack infrastructure
	$(LSTK) stop

for-each-dir:
	./make-for-each.sh $$MAKE_TARGET $$CMD

test-ci-all:
	MAKE_TARGET='test-ci' make for-each-dir

.PHONY: usage install lint start stop for-each-dir test-ci-all
