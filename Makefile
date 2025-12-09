.PHONY: generate verify help

# Generate all README.md files from templates
generate:
	@./generate.sh

# Verify all README.md files are up to date
verify:
	@./generate.sh --verify

# Help
help:
	@echo "Available targets:"
	@echo "  make generate          - Generate all README.md files from templates"
	@echo "  make verify            - Verify all README.md files are up to date"
	@echo ""
	@echo "You can also run the script directly:"
	@echo "  ./generate.sh <dir>          - Generate README for specific directory"
	@echo "  ./generate.sh --verify <dir> - Verify specific directory"


