#!/bin/bash
#
# Generates README.md from README.md.tmpl by replacing {{include:path}} markers
# with the contents of the referenced files.
#
# Templates are in _src/_overlays/, output goes to examples/
#
# Usage:
#   ./generate.sh                    # Process all overlays with README.md.tmpl
#   ./generate.sh <example-name>     # Process specific example
#   ./generate.sh --verify           # Verify all READMEs are up to date
#   ./generate.sh --verify <name>    # Verify specific example
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
OVERLAYS_DIR="$SCRIPT_DIR/_overlays"
EXAMPLES_DIR="$ROOT_DIR/examples"

# Process a single template file
process_template() {
    local template_file="$1"
    local template_dir="$(dirname "$template_file")"

    # Read template and process includes
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ \{\{include:([^}]+)\}\} ]]; then
            local include_path="${BASH_REMATCH[1]}"
            local full_path="$template_dir/$include_path"

            if [[ -f "$full_path" ]]; then
                cat "$full_path"
            else
                echo "# ERROR: File not found: $include_path" >&2
                echo "# ERROR: File not found: $include_path"
            fi
        else
            echo "$line"
        fi
    done < "$template_file"
}

# Generate README for an example
generate_readme() {
    local example_name="$1"
    local overlay_dir="$OVERLAYS_DIR/$example_name"
    local template="$overlay_dir/README.md.tmpl"
    local output_dir="$EXAMPLES_DIR/$example_name"
    local output="$output_dir/README.md"

    if [[ ! -f "$template" ]]; then
        echo "Error: No README.md.tmpl found in $overlay_dir" >&2
        return 1
    fi

    mkdir -p "$output_dir"
    echo "Generating: $output" >&2
    process_template "$template" > "$output"
}

# Verify README is up to date
verify_readme() {
    local example_name="$1"
    local overlay_dir="$OVERLAYS_DIR/$example_name"
    local template="$overlay_dir/README.md.tmpl"
    local output="$EXAMPLES_DIR/$example_name/README.md"

    if [[ ! -f "$template" ]]; then
        echo "Error: No README.md.tmpl found in $overlay_dir" >&2
        return 1
    fi

    if [[ ! -f "$output" ]]; then
        echo "✗ $output does not exist" >&2
        return 1
    fi

    # Generate to temp file and compare
    local tmp_file
    tmp_file=$(mktemp)
    process_template "$template" > "$tmp_file"

    if diff -q "$tmp_file" "$output" > /dev/null 2>&1; then
        echo "✓ $output is up to date"
        rm -f "$tmp_file"
        return 0
    else
        echo "✗ $output is out of date. Run './generate.sh $example_name' to update."
        rm -f "$tmp_file"
        return 1
    fi
}

# Main logic
main() {
    local verify=false
    local target=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verify)
                verify=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [--verify] [example-name]"
                echo ""
                echo "Generates README.md files from _src/_overlays/*/README.md.tmpl to examples/*/"
                echo ""
                echo "Options:"
                echo "  --verify       Check if README.md files are up to date"
                echo "  example-name   Process only the specified example"
                exit 0
                ;;
            *)
                target="$1"
                shift
                ;;
        esac
    done

    local exit_code=0

    if [[ -n "$target" ]]; then
        if [[ "$verify" == true ]]; then
            verify_readme "$target" || exit_code=1
        else
            generate_readme "$target" || exit_code=1
        fi
    else
        # Find all overlays with templates
        local found=false
        for overlay_dir in "$OVERLAYS_DIR"/*/; do
            if [[ -d "$overlay_dir" ]]; then
                local example_name
                example_name=$(basename "$overlay_dir")
                if [[ -f "$overlay_dir/README.md.tmpl" ]]; then
                    found=true
                    if [[ "$verify" == true ]]; then
                        verify_readme "$example_name" || exit_code=1
                    else
                        generate_readme "$example_name" || exit_code=1
                    fi
                fi
            fi
        done

        if [[ "$found" == false ]]; then
            echo "No README.md.tmpl files found in $OVERLAYS_DIR" >&2
            exit 1
        fi
    fi

    if [[ "$verify" != true && $exit_code -eq 0 ]]; then
        echo "Done!" >&2
    fi

    exit $exit_code
}

main "$@"
