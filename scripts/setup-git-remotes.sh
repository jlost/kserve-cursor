#!/bin/bash
# Set up git remotes for ODH multi-fork workflow
# Configures upstream, odh, downstream, and origin remotes
#
# Usage:
#   ./setup-git-remotes.sh                    # Auto-detect repo name, default upstream org
#   ./setup-git-remotes.sh modelmesh-serving  # Explicit repo name
#   ./setup-git-remotes.sh kserve kserve      # Explicit repo name and upstream org
#
# Examples:
#   kserve:              ./setup-git-remotes.sh kserve kserve
#   odh-model-controller: ./setup-git-remotes.sh odh-model-controller opendatahub-io
#   modelmesh-serving:   ./setup-git-remotes.sh modelmesh-serving kserve

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "Not in a git repository."
    exit 1
fi

# Auto-detect repo name from directory or existing remote
detect_repo_name() {
    # Try to extract from existing odh or upstream remote
    for remote in odh upstream origin; do
        if git remote get-url "$remote" 2>/dev/null | grep -oP '[^/]+(?=\.git$)'; then
            return
        fi
    done
    # Fall back to directory name (strip worktree suffixes like -RHOAIENG-1234)
    basename "$(git rev-parse --show-toplevel)" | sed 's/-[A-Z]*-[0-9]*$//'
}

# Parameters
REPO_NAME="${1:-$(detect_repo_name)}"
UPSTREAM_ORG="${2:-kserve}"

log_info "=== ODH Git Remotes Setup ==="
log_info "Repository: ${REPO_NAME}"
log_info "Upstream org: ${UPSTREAM_ORG}"
echo ""

remote_exists() { git remote | grep -q "^${1}$"; }

# Add or update remote
configure_remote() {
    local name=$1
    local url=$2
    if remote_exists "$name"; then
        local current_url
        current_url=$(git remote get-url "$name")
        if [[ "$current_url" == "$url" ]]; then
            log_info "${name}: ${url} (unchanged)"
        else
            git remote set-url "$name" "$url"
            log_info "${name}: ${url} (updated from ${current_url})"
        fi
    else
        git remote add "$name" "$url"
        log_info "${name}: ${url} (added)"
    fi
}

# Standard remotes
configure_remote "upstream" "git@github.com:${UPSTREAM_ORG}/${REPO_NAME}.git"
configure_remote "odh" "git@github.com:opendatahub-io/${REPO_NAME}.git"
configure_remote "downstream" "git@github.com:red-hat-data-services/${REPO_NAME}.git"

# Origin (user's personal fork) - prompt only if missing
if remote_exists "origin"; then
    log_info "origin: $(git remote get-url origin) (unchanged)"
else
    read -p "$(echo -e "${BLUE}[PROMPT]${NC} Enter your personal fork URL (e.g., git@github.com:username/${REPO_NAME}.git): ")" input
    if [[ -n "$input" ]]; then
        git remote add origin "$input"
        log_info "origin: ${input} (added)"
    else
        log_warn "Skipping origin. Add later with: git remote add origin <url>"
    fi
fi

echo ""
log_info "Fetching all remotes..."
git fetch --all

echo ""
log_info "=== Current remotes ==="
git remote -v

echo ""
log_info "=== Setup Complete ==="
