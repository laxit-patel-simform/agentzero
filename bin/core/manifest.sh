#!/usr/bin/env bash

# AgentZero Core: Manifest Module
# Handles parsing of manifest.json and registry.json using PHP.

function parse_manifest_files() {
    local json=$1
    echo "$json" | php -r "\$m = json_decode(file_get_contents('php://stdin'), true); if (isset(\$m['files'])) { foreach (\$m['files'] as \$type => \$list) { foreach (\$list as \$f) echo \"\$f\n\"; } }"
}

function parse_manifest_dependencies() {
    local json=$1
    # Extracts the agent dependencies from the manifest
    echo "$json" | php -r "\$m = json_decode(file_get_contents('php://stdin'), true); if (isset(\$m['dependencies']['agents'])) { foreach (\$m['dependencies']['agents'] as \$a) echo \"\$a\n\"; }"
}

function parse_registry() {
    local json=$1
    echo "$json" | php -r "\$r = json_decode(file_get_contents('php://stdin'), true); if (isset(\$r['agents'])) { foreach (\$r['agents'] as \$a) { printf(\"${SET_COLOR_BOLD}%-25s${SET_COLOR_RESET} %-10s %-40s\n\", \$a['id'], \$a['version'], \$a['description']); } }"
}
