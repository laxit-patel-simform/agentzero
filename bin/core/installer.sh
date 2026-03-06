#!/usr/bin/env bash

# AgentZero Core: Installer Module
# Handles the actual file system operations.

function execute_install_plan() {
    log_info "Executing installation plan for: ${INSTALL_PLAN[*]}"
    
    for agent_id in "${INSTALL_PLAN[@]}"; do
        deploy_single_agent "$agent_id"
    done
}

function deploy_single_agent() {
    local agent_id=$1
    log_info "Processing Agent: $agent_id..."
    
    local manifest_json
    if [ "$MODE" == "DEV" ]; then
        local agent_path="$AGENTS_DIR/$agent_id"
        if [ ! -d "$agent_path" ]; then log_error "Agent '$agent_id' not found."; exit 1; fi
        manifest_json=$(cat "$agent_path/manifest.json")
        
        # Local copy
        mkdir -p .github
        cp -rv "$agent_path/stubs/.github/"* .github/
    else
        manifest_json=$(fetch_remote_file "agents/$agent_id/manifest.json")
        if [ -z "$manifest_json" ]; then log_error "Manifest for '$agent_id' not found."; exit 1; fi
        
        # Extract files from manifest and download each
        local files=$(parse_manifest_files "$manifest_json")
        
        for f in $files; do
            log_info "  Downloading $f..."
            # The manifest file path (e.g. .github/agents/file.md) is relative to the payload root
            # so we download it directly to the current repository root.
            local target_dir=$(dirname "$f")
            mkdir -p "$target_dir"
            fetch_remote_file "agents/$agent_id/stubs/$f" > "$f"
            
            if [ -s "$f" ]; then
                log_success "    Successfully downloaded $f"
            else
                log_error "    Failed to download $f"
                rm "$f" # Cleanup empty file
            fi
        done
    fi
}

function remove_single_agent() {
    local agent_id=$1
    log_info "Uninstalling Agent: $agent_id..."
    
    local manifest_json
    if [ "$MODE" == "DEV" ]; then
        local agent_path="$AGENTS_DIR/$agent_id"
        if [ ! -d "$agent_path" ]; then log_error "Agent '$agent_id' not found in local agents/."; exit 1; fi
        manifest_json=$(cat "$agent_path/manifest.json")
    else
        manifest_json=$(fetch_remote_file "agents/$agent_id/manifest.json")
    fi

    if [ -z "$manifest_json" ]; then
        log_error "Could not fetch manifest for '$agent_id' to perform cleanup."
        exit 1
    fi

    # Extract files from manifest and remove each
    local files=$(parse_manifest_files "$manifest_json")
    for f in $files; do
        local target=".github/$f"
        if [ -f "$target" ]; then
            rm -v "$target"
            log_success "  Removed $f"
        fi
    done

    # Clean up empty directories in .github
    find .github -type d -empty -delete 2>/dev/null
    log_success "Agent '$agent_id' uninstalled."
}
