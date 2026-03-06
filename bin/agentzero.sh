#!/usr/bin/env bash

# AgentZero: The Awesome Copilot Agent Deployer (PHP Edition)
# This is the bootstrapper script that orchestrates core modules.

SET_COLOR_RESET=$(tput sgr0)
SET_COLOR_PRIMARY=$(tput setaf 4)
SET_COLOR_PURPLE=$(tput setaf 5)
SET_COLOR_CYAN=$(tput setaf 6)
SET_COLOR_SUCCESS=$(tput setaf 2)
SET_COLOR_ERROR=$(tput setaf 1)
SET_COLOR_BOLD=$(tput bold)

# Configuration (Overridable via ENV)
REPO_USER="${AGENTZERO_USER:-laxit-patel-simform}"
REPO_NAME="${AGENTZERO_REPO:-agentzero}"
REPO_BRANCH="${AGENTZERO_BRANCH:-main}"
REPO_RAW_URL="https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$REPO_BRANCH"

AGENTS_DIR="./agents"

# Detect Mode
if [ -d "$AGENTS_DIR" ] && [ -d "./bin/core" ]; then
    MODE="DEV"
    CORE_DIR="./bin/core"
else
    MODE="REMOTE"
    CORE_DIR="/tmp/agentzero-core"
    mkdir -p "$CORE_DIR"
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

# 1. Source Remote Module first to enable fetching others
if [ "$MODE" == "DEV" ]; then
    source "$CORE_DIR/remote.sh"
else
    # Bootstrap remote module via curl
    curl -sSL "$REPO_RAW_URL/bin/core/remote.sh" > "$CORE_DIR/remote.sh"
    source "$CORE_DIR/remote.sh"
fi

# 2. Fetch/Source remaining modules
MODULES=("manifest.sh" "resolver.sh" "installer.sh")
for mod in "${MODULES[@]}"; do
    if [ "$MODE" == "REMOTE" ]; then
        fetch_remote_file "bin/core/$mod" > "$CORE_DIR/$mod"
    fi
    source "$CORE_DIR/$mod"
done

function show_help() {
    echo -e "${SET_COLOR_BOLD}AgentZero: Meta-Agent Deployer${SET_COLOR_RESET}"
    echo "Usage: agentzero [command]"
    echo ""
    echo "Mode:   $MODE"
    echo "Source: $REPO_USER/$REPO_NAME ($REPO_BRANCH)"
    echo ""
    echo "Commands:"
    echo "  list        List all available Agents"
    echo "  deploy      Deploy an Agent and its dependencies"
    echo "  doctor      Check local environment for dependencies"
    echo "  help        Show this help message"
}

function list_agents() {
    if [ "$MODE" == "DEV" ]; then
        log_info "Developer Mode: Scanning local $AGENTS_DIR..."
        printf "%-25s %-10s %-40s\n" "ID" "VERSION" "DESCRIPTION"
        echo "--------------------------------------------------------------------------------"
        for d in $AGENTS_DIR/*; do
            if [ -d "$d" ] && [ -f "$d/manifest.json" ]; then
                local id=$(basename "$d")
                php -r "\$m = json_decode(file_get_contents('$d/manifest.json'), true); printf(\"${SET_COLOR_BOLD}%-25s${SET_COLOR_RESET} %-10s %-40s\n\", '$id', \$m['version'] ?? '', \$m['description'] ?? '');"
            fi
        done
    else
        log_info "Remote Mode: Fetching registry from $REPO_USER/$REPO_NAME ($REPO_BRANCH)..."
        local registry_json=$(fetch_remote_file "registry.json")
        if [ -z "$registry_json" ]; then log_error "Could not fetch registry."; exit 1; fi
        printf "%-25s %-10s %-40s\n" "ID" "VERSION" "DESCRIPTION"
        echo "--------------------------------------------------------------------------------"
        parse_registry "$registry_json"
    fi
    echo ""
}

function run_doctor() {
    log_info "Checking local environment..."
    local deps=("php" "composer" "gh" "git" "curl")
    local missing=0
    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then log_success "$dep is installed"; else log_error "$dep is NOT installed"; missing=$((missing + 1)); fi
    done
    [ $missing -eq 0 ] && log_success "Environment ready!" || log_error "Missing $missing dependencies."
}

show_logo

case "$1" in
    list) list_agents ;;
    deploy)
        if [ -z "$2" ]; then log_error "Specify an agent ID."; exit 1; fi
        resolve_dependencies "$2"
        execute_install_plan
        ;;
    doctor) run_doctor ;;
    help|*) show_help ;;
esac
