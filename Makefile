.PHONY: validate lint test setup help

help:
	@echo "Targets:"
	@echo "  make validate   Run all self-checks (frontmatter, YAML, shellcheck, dry-run)"
	@echo "  make lint       Alias for validate"
	@echo "  make test       Alias for validate"
	@echo "  make setup      Run ./setup.sh interactively against the current directory"

validate:
	@bash scripts/validate.sh

lint: validate
test: validate

setup:
	@./setup.sh
