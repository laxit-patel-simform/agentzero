#!/usr/bin/env bash

# AgentZero Core: Resolver Module
# Recursively builds the flat dependency list for an agent.

# Global list of agents to install
INSTALL_PLAN=()

function resolve_dependencies() {
    local agent_id=$1
    
    # Check if agent already in plan to prevent cycles
    for existing in "${INSTALL_PLAN[@]}"; do
        if [ "$existing" == "$agent_id" ]; then
            return
        fi
    done
    
    # Fetch manifest and resolve sub-dependencies
    local manifest_json
    if [ "$MODE" == "DEV" ]; then
        manifest_json=$(cat "$AGENTS_DIR/$agent_id/manifest.json")
    else
        manifest_json=$(fetch_remote_file "agents/$agent_id/manifest.json")
    fi
    
    if [ -z "$manifest_json" ]; then
        log_error "Could not find manifest for agent '$agent_id'."
        exit 1
    fi
    
    # Get sub-dependencies from manifest
    local deps=$(parse_manifest_dependencies "$manifest_json")
    for dep in $deps; do
        resolve_dependencies "$dep"
    done
    
    # Add this agent to the end of the installation plan
    INSTALL_PLAN+=("$agent_id")
}
