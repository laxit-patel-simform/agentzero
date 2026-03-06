#!/usr/bin/env bash

# AgentZero Core: Remote Module
# Handles all network operations for fetching files from GitHub.

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
