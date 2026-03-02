#!/usr/bin/env bash

# Verification Harness: awesome-copilot-opensource
# Usage: ./verify.sh

SET_COLOR_RESET=$(tput sgr0)
SET_COLOR_PRIMARY=$(tput setaf 4)
SET_COLOR_SUCCESS=$(tput setaf 2)
SET_COLOR_ERROR=$(tput setaf 1)
SET_COLOR_BOLD=$(tput bold)

FAILED=0

function log_step() { echo -e "${SET_COLOR_BOLD}--- $1 ---${SET_COLOR_RESET}"; }
function log_pass() { echo -e "  ${SET_COLOR_SUCCESS}PASS${SET_COLOR_RESET} $1"; }
function log_fail() { echo -e "  ${SET_COLOR_ERROR}FAIL${SET_COLOR_RESET} $1"; FAILED=1; }

# 1. Verify AgentZero Script
log_step "Verifying AgentZero Script"
if bash -n "$(dirname "$0")/agentzero.sh"; then
    log_pass "agentzero.sh syntax is valid"
else
    log_fail "agentzero.sh has syntax errors"
fi

# 2. Verify Agent Packs
log_step "Verifying Agent Packs Structure"
for pack_dir in packs/*; do
    if [ -d "$pack_dir" ]; then
        pack_id=$(basename "$pack_dir")
        
        # Check manifest existence
        if [ ! -f "$pack_dir/manifest.json" ]; then
            log_fail "Pack '$pack_id' is missing manifest.json"
            continue
        fi

        # Check manifest validity (JSON)
        if php -r "json_decode(file_get_contents('$pack_dir/manifest.json')) ?: exit(1);" 2>/dev/null; then
            log_pass "Pack '$pack_id' manifest is valid JSON"
        else
            log_fail "Pack '$pack_id' manifest has invalid JSON"
            continue
        fi

        # Check stubs existence for each file in manifest
        log_info="Checking stubs for $pack_id..."
        
        # Get all files from manifest.json using PHP
        files=$(php -r "\$m = json_decode(file_get_contents('$pack_dir/manifest.json'), true); if (isset(\$m['files'])) { foreach (\$m['files'] as \$type => \$list) { foreach (\$list as \$f) echo \"\$f\n\"; } }")

        for f in $files; do
            # The manifest paths are relative to the target project root (.github/...)
            # We need to find them in packs/<id>/stubs/.github/...
            stub_path="$pack_dir/stubs/$f"
            if [ -f "$stub_path" ]; then
                log_pass "  Found stub: $f"
                
                # Verify YAML frontmatter in markdown files
                if [[ "$f" == *.md ]]; then
                    if head -n 1 "$stub_path" | grep -q "^---$"; then
                        log_pass "    Frontmatter detected in $f"
                    else
                        log_fail "    Frontmatter MISSING in $f"
                    fi
                fi
            else
                log_fail "  Missing stub file: $f (expected at $stub_path)"
            fi
        done
    fi
done

echo ""
if [ $FAILED -eq 0 ]; then
    echo -e "${SET_COLOR_SUCCESS}${SET_COLOR_BOLD}Verification Successful!${SET_COLOR_RESET}"
    exit 0
else
    echo -e "${SET_COLOR_ERROR}${SET_COLOR_BOLD}Verification Failed!${SET_COLOR_RESET}"
    exit 1
fi
