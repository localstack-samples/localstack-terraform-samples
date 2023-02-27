.PHONY: lint

lint:
	@echo "==> Linting terraform code"
	@terraform fmt -diff=true -recursive -write=true
