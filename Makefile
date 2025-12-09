.PHONY: generate verify build build-verify all clean help

# Generate all README.md files from templates
generate:
	@./_src/generate.sh

# Verify all README.md files are up to date
verify:
	@./_src/generate.sh --verify

# Build all examples from overlays to examples/
build:
	@./_src/build.sh

# Verify examples/ is up to date
build-verify:
	@./_src/build.sh --verify

# Full build + generate (build first, then generate README into examples/)
all: build generate

# Clean generated examples
clean:
	@rm -rf examples/
	@echo "Cleaned examples/ directory"

# Help
help:
	@echo "Available targets:"
	@echo ""
	@echo "  make generate       - Generate README.md files from templates"
	@echo "  make verify         - Verify README.md files are up to date"
	@echo "  make build          - Build examples/ from _src/_overlays/"
	@echo "  make build-verify   - Verify examples/ is up to date"
	@echo "  make all            - Run build and generate"
	@echo "  make clean          - Remove examples/ directory"
	@echo ""
	@echo "Creating new examples:"
	@echo "  ./_src/new-example.sh <name> [description]"
	@echo ""
	@echo "Directory structure:"
	@echo "  _src/            - All source files (internal)"
	@echo "  examples/        - Built, self-contained examples (generated)"
