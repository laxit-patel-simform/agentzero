#!/usr/bin/env bash

# Envoy: The Awesome Copilot Agent Pack Manager (PHP Edition)
# Usage: ./envoy.sh [command]

SET_COLOR_RESET=$(tput sgr0)
SET_COLOR_PRIMARY=$(tput setaf 4)
SET_COLOR_SUCCESS=$(tput setaf 2)
SET_COLOR_ERROR=$(tput setaf 1)
SET_COLOR_BOLD=$(tput bold)

PACKS_DIR="./packs"

function log_info() { echo -e "${SET_COLOR_PRIMARY}info${SET_COLOR_RESET}  $1"; }
function log_success() { echo -e "${SET_COLOR_SUCCESS}success${SET_COLOR_RESET} $1"; }
function log_error() { echo -e "${SET_COLOR_ERROR}error${SET_COLOR_RESET}   $1"; }

function show_help() {
    echo -e "${SET_COLOR_BOLD}Envoy: Agent Pack Manager${SET_COLOR_RESET}"
    echo "Usage: ./envoy.sh [command]"
    echo ""
    echo "Commands:"
    echo "  list        List all available Agent Packs"
    echo "  install     Install an Agent Pack into the current repository"
    echo "  doctor      Check local environment for dependencies"
    echo "  help        Show this help message"
}

function get_manifest_val() {
    local pack_path=$1
    local key=$2
    php -r "\$m = json_decode(file_get_contents('$pack_path/manifest.json'), true); echo \$m['$key'] ?? '';"
}

function list_packs() {
    log_info "Scanning for Agent Packs in $PACKS_DIR..."
    echo ""
    printf "%-25s %-10s %-40s
" "ID" "VERSION" "DESCRIPTION"
    echo "--------------------------------------------------------------------------------"
    
    for d in $PACKS_DIR/*; do
        if [ -d "$d" ] && [ -f "$d/manifest.json" ]; then
            local id=$(basename "$d")
            local version=$(get_manifest_val "$d" "version")
            local desc=$(get_manifest_val "$d" "description")
            printf "${SET_COLOR_BOLD}%-25s${SET_COLOR_RESET} %-10s %-40s
" "$id" "$version" "$desc"
        fi
    done
    echo ""
}

function install_pack() {
    local pack_id=$1
    if [ -z "$pack_id" ]; then
        log_error "Please specify a pack ID. Usage: ./envoy.sh install <pack-id>"
        exit 1
    fi

    local pack_path="$PACKS_DIR/$pack_id"
    if [ ! -d "$pack_path" ]; then
        log_error "Pack '$pack_id' not found."
        exit 1
    fi

    log_info "Installing $pack_id..."

    # Check for stubs
    if [ ! -d "$pack_path/stubs/.github" ]; then
        log_error "Pack '$pack_id' is missing stubs/.github directory."
        exit 1
    fi

    # Create local .github directory if not exists
    mkdir -p .github

    # Copy files
    cp -rv "$pack_path/stubs/.github/." .github/
    
    log_success "Pack '$pack_id' installed successfully into .github/"
    echo "Next steps: Restart your IDE's AI assistant to load the new agents and prompts."
}

function run_doctor() {
    log_info "Checking local environment..."
    
    local deps=("php" "composer" "gh" "git")
    local missing=0

    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            log_success "$dep is installed ($( $dep --version | head -n 1 ))"
        else
            log_error "$dep is NOT installed"
            missing=$((missing + 1))
        fi
    done

    if [ $missing -eq 0 ]; then
        log_success "Environment is ready for PHP Agent Packs!"
    else
        log_error "Found $missing missing dependencies. Some packs may not function correctly."
    fi
}

case "$1" in
    list)
        list_packs
        ;;
    install)
        install_pack "$2"
        ;;
    doctor)
        run_doctor
        ;;
    help|*)
        show_help
        ;;
esac
