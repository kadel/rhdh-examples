#!/bin/bash
#
# Generates README.md from README.md.tmpl by replacing {{include:path}} markers
# with the contents of the referenced files.
#
# Usage:
#   ./generate.sh                    # Process all directories with README.md.tmpl
#   ./generate.sh <directory>        # Process specific directory
#   ./generate.sh --verify           # Verify all READMEs are up to date
#   ./generate.sh --verify <dir>     # Verify specific directory
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Generate README for a directory
generate_readme() {
    local dir="$1"
    local template="$dir/README.md.tmpl"
    local output="$dir/README.md"
    
    if [[ ! -f "$template" ]]; then
        echo "Error: No README.md.tmpl found in $dir" >&2
        return 1
    fi
    
    echo "Generating: $output" >&2
    process_template "$template" > "$output"
}

# Verify README is up to date
verify_readme() {
    local dir="$1"
    local template="$dir/README.md.tmpl"
    local output="$dir/README.md"
    
    if [[ ! -f "$template" ]]; then
        echo "Error: No README.md.tmpl found in $dir" >&2
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
        echo "✗ $output is out of date. Run './generate.sh $dir' to update."
        rm -f "$tmp_file"
        return 1
    fi
}

# Main logic
main() {
    local verify=false
    local target_dir=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verify)
                verify=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [--verify] [directory]"
                echo ""
                echo "Options:"
                echo "  --verify    Check if README.md files are up to date"
                echo "  directory   Process only the specified directory"
                echo ""
                echo "If no directory is specified, all directories with README.md.tmpl are processed."
                exit 0
                ;;
            *)
                target_dir="$1"
                shift
                ;;
        esac
    done
    
    local exit_code=0
    
    if [[ -n "$target_dir" ]]; then
        # Make path absolute if relative
        if [[ ! "$target_dir" = /* ]]; then
            target_dir="$SCRIPT_DIR/$target_dir"
        fi
        
        if [[ "$verify" == true ]]; then
            verify_readme "$target_dir" || exit_code=1
        else
            generate_readme "$target_dir" || exit_code=1
        fi
    else
        # Find all directories with templates
        local found=false
        while IFS= read -r template_file; do
            found=true
            local dir="$(dirname "$template_file")"
            if [[ "$verify" == true ]]; then
                verify_readme "$dir" || exit_code=1
            else
                generate_readme "$dir" || exit_code=1
            fi
        done < <(find "$SCRIPT_DIR" -name "README.md.tmpl" -type f 2>/dev/null)
        
        if [[ "$found" == false ]]; then
            echo "No README.md.tmpl files found" >&2
            exit 1
        fi
    fi
    
    if [[ "$verify" != true && $exit_code -eq 0 ]]; then
        echo "Done!" >&2
    fi
    
    exit $exit_code
}

main "$@"
