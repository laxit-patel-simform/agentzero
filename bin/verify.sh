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

# 2. Verify Agents Structure
log_step "Verifying Agents Structure"
for agent_dir in agents/*; do
    if [ -d "$agent_dir" ]; then
        agent_id=$(basename "$agent_dir")
        
        # Check manifest existence
        if [ ! -f "$agent_dir/manifest.json" ]; then
            log_fail "Agent '$agent_id' is missing manifest.json"
            continue
        fi

        # Check manifest validity (JSON)
        if php -r "json_decode(file_get_contents('$agent_dir/manifest.json')) ?: exit(1);" 2>/dev/null; then
            log_pass "Agent '$agent_id' manifest is valid JSON"
        else
            log_fail "Agent '$agent_id' manifest has invalid JSON"
            continue
        fi

        # Check stubs existence for each file in manifest
        files=$(php -r "\$m = json_decode(file_get_contents('$agent_dir/manifest.json'), true); if (isset(\$m['files'])) { foreach (\$m['files'] as \$type => \$list) { foreach (\$list as \$f) echo \"\$f\n\"; } }")

        for f in $files; do
            stub_path="$agent_dir/stubs/$f"
            if [ -f "$stub_path" ]; then
                # Verify YAML frontmatter in markdown files
                if [[ "$f" == *.md ]]; then
                    # Extract content between first two --- lines
                    frontmatter=$(sed -n '/^---$/,/^---$/p' "$stub_path" | sed '1d;$d')
                    if [ -n "$frontmatter" ]; then
                        log_pass "    Frontmatter detected in $f"

                        # Basic YAML structural check using PHP (checking for invalid list syntax etc)
                        # We look for unquoted commas which are common errors in YAML lists not using []
                        if echo "$frontmatter" | grep -q ".*: .*,.*" && ! echo "$frontmatter" | grep -q ".*: \[.*\]"; then
                            log_fail "    Invalid YAML syntax in $f: suspected unquoted list (use [item1, item2])"
                        else
                            log_pass "    Frontmatter structure looks valid"
                        fi
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
