#!/usr/bin/env bash

# AgentZero: The Awesome Copilot Agent Deployer (PHP Edition)
# Usage: ./agentzero.sh [command]

SET_COLOR_RESET=$(tput sgr0)
SET_COLOR_PRIMARY=$(tput setaf 4)
SET_COLOR_PURPLE=$(tput setaf 5)
SET_COLOR_CYAN=$(tput setaf 6)
SET_COLOR_SUCCESS=$(tput setaf 2)
SET_COLOR_ERROR=$(tput setaf 1)
SET_COLOR_BOLD=$(tput bold)

# Configuration (Overridable via ENV)
REPO_USER="${AGENTZERO_USER:-simform-git}"
REPO_NAME="${AGENTZERO_REPO:-awesome-copilot-opensource}"
REPO_BRANCH="${AGENTZERO_BRANCH:-main}"
REPO_RAW_URL="https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$REPO_BRANCH"

AGENTS_DIR="./agents"

# Detect Mode
if [ -d "$AGENTS_DIR" ]; then
    MODE="DEV"
else
    MODE="REMOTE"
fi

function fetch_remote_file() {
    local file_path=$1
    # Try using gh api first (better for private repos)
    if command -v gh >/dev/null 2>&1; then
        gh api -H "Accept: application/vnd.github.v3.raw" "/repos/$REPO_USER/$REPO_NAME/contents/$file_path?ref=$REPO_BRANCH" 2>/dev/null
        if [ $? -eq 0 ]; then return 0; fi
    fi
    # Fallback to curl (for public repos or if gh is missing)
    curl -sSL "$REPO_RAW_URL/$file_path"
}

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
    echo "Mode:   $MODE"
    echo "Source: $REPO_USER/$REPO_NAME ($REPO_BRANCH)"
    echo ""
    echo "Commands:"
    echo "  list        List all available Agents"
    echo "  deploy      Deploy an Agent into the current repository"
    echo "  doctor      Check local environment for dependencies"
    echo "  help        Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  AGENTZERO_USER    Override GitHub user/org (default: simform-git)"
    echo "  AGENTZERO_REPO    Override GitHub repository (default: awesome-copilot-opensource)"
    echo "  AGENTZERO_BRANCH  Override GitHub branch (default: main)"
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
        if [ -z "$registry_json" ]; then
            log_error "Could not fetch registry from GitHub."
            exit 1
        fi

        printf "%-25s %-10s %-40s\n" "ID" "VERSION" "DESCRIPTION"
        echo "--------------------------------------------------------------------------------"
        echo "$registry_json" | php -r "\$r = json_decode(file_get_contents('php://stdin'), true); if (isset(\$r['agents'])) { foreach (\$r['agents'] as \$a) { printf(\"${SET_COLOR_BOLD}%-25s${SET_COLOR_RESET} %-10s %-40s\n\", \$a['id'], \$a['version'], \$a['description']); } }"
    fi
    echo ""
}

function deploy_agent() {
    local agent_id=$1
    if [ -z "$agent_id" ]; then
        log_error "Please specify an agent ID. Usage: ./agentzero.sh deploy <agent-id>"
        exit 1
    fi

    if [ "$MODE" == "DEV" ]; then
        local agent_path="$AGENTS_DIR/$agent_id"
        log_info "Developer Mode: Deploying from $agent_path..."
        if [ ! -d "$agent_path" ]; then log_error "Agent '$agent_id' not found."; exit 1; fi
        mkdir -p .github
        cp -rv "$agent_path/stubs/.github/." .github/
    else
        log_info "Remote Mode: Deploying $agent_id from $REPO_USER/$REPO_NAME ($REPO_BRANCH)..."
        local manifest_json=$(fetch_remote_file "agents/$agent_id/manifest.json")
        if [ -z "$manifest_json" ]; then
            log_error "Could not find manifest for agent '$agent_id' on GitHub."
            exit 1
        fi

        # Extract files from manifest and download each
        local files=$(echo "$manifest_json" | php -r "\$m = json_decode(file_get_contents('php://stdin'), true); if (isset(\$m['files'])) { foreach (\$m['files'] as \$type => \$list) { foreach (\$list as \$f) echo \"\$f\n\"; } }")
        
        for f in $files; do
            log_info "  Downloading $f..."
            local target_dir=$(dirname ".github/$f")
            mkdir -p "$target_dir"
            fetch_remote_file "agents/$agent_id/stubs/$f" > ".github/$f"
            
            if [ -s ".github/$f" ]; then
                log_success "    Successfully downloaded $f"
            else
                log_error "    Failed to download $f"
                rm ".github/$f" # Cleanup empty file on failure
            fi
        done
    fi

    log_success "Agent '$agent_id' deployed successfully into .github/"
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
        log_error "Found $missing missing dependencies. Some agents may not function correctly."
    fi
}

show_logo

case "$1" in
    list)
        list_agents
        ;;
    deploy)
        deploy_agent "$2"
        ;;
    doctor)
        run_doctor
        ;;
    help|*)
        show_help
        ;;
esac
