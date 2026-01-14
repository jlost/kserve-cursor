#!/bin/bash
# Setup MCP (Model Context Protocol) servers for Cursor
# Generates ~/.cursor/mcp.json from environment variables using a template

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="${SCRIPT_DIR}/mcp.json.tmpl"
MCP_CONFIG_DIR="${HOME}/.cursor"
MCP_CONFIG_FILE="${MCP_CONFIG_DIR}/mcp.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo "============================================"
echo "MCP Configuration Setup for Cursor"
echo "============================================"
echo ""

# Required environment variables
REQUIRED_VARS=(
    "GITHUB_MCP_TOKEN"
    "JIRA_URL"
    "JIRA_PERSONAL_TOKEN"
    "SLACK_XOXC_TOKEN"
    "SLACK_XOXD_TOKEN"
)

# Check all required variables
missing_vars=()
for var in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var}" ]]; then
        missing_vars+=("$var")
    else
        print_info "$var is configured"
    fi
done

echo ""

if [[ ${#missing_vars[@]} -gt 0 ]]; then
    print_error "Missing required environment variables:"
    for var in "${missing_vars[@]}"; do
        echo "  - $var"
    done
    echo ""
    echo "Add the following to your shell configuration (~/.zshenv or ~/.bashrc):"
    echo ""
    echo "  # GitHub MCP"
    echo "  export GITHUB_MCP_TOKEN=\"ghp_xxxx\""
    echo ""
    echo "  # JIRA integration"
    echo "  export JIRA_URL=\"https://issues.redhat.com\""
    echo "  export JIRA_PERSONAL_TOKEN=\"your-token\""
    echo ""
    echo "  # Slack integration (from browser cookies)"
    echo "  export SLACK_XOXC_TOKEN=\"xoxc-xxxx\""
    echo "  export SLACK_XOXD_TOKEN=\"xoxd-xxxx\""
    echo ""
    exit 1
fi

# Ensure template exists
if [[ ! -f "${TEMPLATE_FILE}" ]]; then
    print_error "Template file not found: ${TEMPLATE_FILE}"
    exit 1
fi

# Create config directory if needed
mkdir -p "${MCP_CONFIG_DIR}"

# Backup existing config
if [[ -f "${MCP_CONFIG_FILE}" ]]; then
    backup_file="${MCP_CONFIG_FILE}.backup.$(date +%Y%m%d%H%M%S)"
    print_info "Backing up existing config to ${backup_file}"
    cp "${MCP_CONFIG_FILE}" "${backup_file}"
fi

# Generate config from template using envsubst
print_info "Generating MCP configuration from template..."

envsubst < "${TEMPLATE_FILE}" > "${MCP_CONFIG_FILE}"

echo ""
echo "============================================"
echo "Setup complete!"
echo "============================================"
echo ""
print_info "MCP configuration written to ${MCP_CONFIG_FILE}"
echo ""
echo "Configured MCP servers:"
echo "  - github"
echo "  - mcp-atlassian (JIRA)"
echo "  - slack"
echo ""
echo "Restart Cursor for changes to take effect."
