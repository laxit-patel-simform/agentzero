#!/usr/bin/env bash

# AgentZero: The Awesome Copilot Agent Pack Deployer (PHP Edition)
# Usage: ./agentzero.sh [command]

SET_COLOR_RESET=$(tput sgr0)
SET_COLOR_PRIMARY=$(tput setaf 4)
SET_COLOR_PURPLE=$(tput setaf 5)
SET_COLOR_CYAN=$(tput setaf 6)
SET_COLOR_SUCCESS=$(tput setaf 2)
SET_COLOR_ERROR=$(tput setaf 1)
SET_COLOR_BOLD=$(tput bold)

# Configuration
REPO_USER="simform-git"
REPO_NAME="awesome-copilot-opensource"
REPO_BRANCH="foundation"
REPO_RAW_URL="https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$REPO_BRANCH"

PACKS_DIR="./packs"

# Detect Mode
if [ -d "$PACKS_DIR" ]; then
    MODE="DEV"
else
    MODE="REMOTE"
fi

function show_logo() {
    echo -e "${SET_COLOR_PURPLE}${SET_COLOR_BOLD}"
    echo "  █████╗  ██████╗ ███████╗███╗   ██╗████████╗███████╗███████╗██████╗  ██████╗ "
    echo " ██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝╚══███╔╝██╔════╝██╔══██╗██╔═══██╗"
    echo " ███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║     ███╔╝ █████╗  ██████╔╝██║   ██║"
    echo " ██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║    ███╔╝  ██╔══╝  ██╔══██╗██║   ██║"
    echo " ██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║   ███████╗███████╗██║  ██║╚██████╔╝"
    echo " ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ "
    echo -e "${SET_COLOR_RESET}"
}

function log_info() { echo -e "${SET_COLOR_CYAN}info${SET_COLOR_RESET}  $1"; }
function log_success() { echo -e "${SET_COLOR_SUCCESS}success${SET_COLOR_RESET} $1"; }
function log_error() { echo -e "${SET_COLOR_ERROR}error${SET_COLOR_RESET}   $1"; }

function show_help() {
    echo -e "${SET_COLOR_BOLD}AgentZero: Meta-Agent Deployer${SET_COLOR_RESET}"
    echo "Usage: ./agentzero.sh [command]"
    echo ""
    echo "Mode: $MODE"
    echo ""
    echo "Commands:"
    echo "  list        List all available Agent Packs"
    echo "  deploy      Deploy an Agent Pack into the current repository"
    echo "  doctor      Check local environment for dependencies"
    echo "  help        Show this help message"
}

function list_packs() {
    if [ "$MODE" == "DEV" ]; then
        log_info "Developer Mode: Scanning local $PACKS_DIR..."
        printf "%-25s %-10s %-40s\n" "ID" "VERSION" "DESCRIPTION"
        echo "--------------------------------------------------------------------------------"
        for d in $PACKS_DIR/*; do
            if [ -d "$d" ] && [ -f "$d/manifest.json" ]; then
                local id=$(basename "$d")
                php -r "\$m = json_decode(file_get_contents('$d/manifest.json'), true); printf(\"${SET_COLOR_BOLD}%-25s${SET_COLOR_RESET} %-10s %-40s\n\", '$id', \$m['version'] ?? '', \$m['description'] ?? '');"
            fi
        done
    else
        log_info "Remote Mode: Fetching registry from $REPO_RAW_URL..."
        local registry_json=$(curl -sSL "$REPO_RAW_URL/registry.json")
        if [ $? -ne 0 ] || [ -z "$registry_json" ]; then
            log_error "Could not fetch registry from GitHub."
            exit 1
        fi

        printf "%-25s %-10s %-40s\n" "ID" "VERSION" "DESCRIPTION"
        echo "--------------------------------------------------------------------------------"
        php -r "\$r = json_decode('$registry_json', true); if (isset(\$r['packs'])) { foreach (\$r['packs'] as \$p) { printf(\"${SET_COLOR_BOLD}%-25s${SET_COLOR_RESET} %-10s %-40s\n\", \$p['id'], \$p['version'], \$p['description']); } }"
    fi
    echo ""
}

function deploy_pack() {
    local pack_id=$1
    if [ -z "$pack_id" ]; then
        log_error "Please specify a pack ID. Usage: ./agentzero.sh deploy <pack-id>"
        exit 1
    fi

    if [ "$MODE" == "DEV" ]; then
        local pack_path="$PACKS_DIR/$pack_id"
        log_info "Developer Mode: Deploying from $pack_path..."
        if [ ! -d "$pack_path" ]; then log_error "Pack '$pack_id' not found."; exit 1; fi
        mkdir -p .github
        cp -rv "$pack_path/stubs/.github/." .github/
    else
        log_info "Remote Mode: Deploying $pack_id from $REPO_RAW_URL..."
        local manifest_json=$(curl -sSL "$REPO_RAW_URL/packs/$pack_id/manifest.json")
        if [ $? -ne 0 ] || [ -z "$manifest_json" ]; then
            log_error "Could not find manifest for pack '$pack_id' on GitHub."
            exit 1
        fi

        # Extract files from manifest and download each
        local files=$(php -r "\$m = json_decode('$manifest_json', true); if (isset(\$m['files'])) { foreach (\$m['files'] as \$type => \$list) { foreach (\$list as \$f) echo \"\$f\n\"; } }")
        
        for f in $files; do
            log_info "  Downloading $f..."
            local target_dir=$(dirname ".github/$f")
            mkdir -p "$target_dir"
            
            # Use curl to fetch the stub
            # Paths in manifest are like .github/agents/...
            # Remote paths are packs/<id>/stubs/.github/agents/...
            curl -sSL "$REPO_RAW_URL/packs/$pack_id/stubs/$f" -o ".github/$f"
            
            if [ $? -eq 0 ]; then
                log_success "    Successfully downloaded $f"
            else
                log_error "    Failed to download $f"
            fi
        done
    fi

    log_success "Pack '$pack_id' deployed successfully into .github/"
    echo "Next steps: Restart your IDE's AI assistant to load the new agents and prompts."
}

function run_doctor() {
    log_info "Checking local environment..."
    local deps=("php" "composer" "gh" "git" "curl")
    local missing=0

    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            log_success "$dep is installed"
        else
            log_error "$dep is NOT installed"
            missing=$((missing + 1))
        fi
    done

    if [ $missing -eq 0 ]; then
        log_success "Environment is ready for AgentZero!"
    else
        log_error "Found $missing missing dependencies. Some packs may not function correctly."
    fi
}

show_logo

case "$1" in
    list)
        list_packs
        ;;
    deploy)
        deploy_pack "$2"
        ;;
    doctor)
        run_doctor
        ;;
    help|*)
        show_help
        ;;
esac
