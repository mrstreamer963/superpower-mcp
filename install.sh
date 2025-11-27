#!/bin/bash

# Superpowers MCP Server - Installation Script
# 
# This script installs the Superpowers MCP server for use with Augment CLI
# via Model Context Protocol (MCP).
#
# Usage:
#   ./install.sh          # Install or manage (auto-detect)
#   ./install.sh install  # Force install
#   ./install.sh update   # Update superpowers repository
#   ./install.sh remove   # Uninstall

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration - dynamically set based on user's home
SUPERPOWERS_REPO_DIR="${HOME}/.augment/superpowers"
PERSONAL_SKILLS_DIR="${HOME}/.augment/skills"
AUGMENT_SETTINGS="${HOME}/.augment/settings.json"
REPO_URL="https://github.com/obra/superpowers.git"

# Detect where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MCP_SERVER_PATH="${SCRIPT_DIR}/superpowers-mcp.js"

# Banner
show_banner() {
    echo ""
    printf "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}║                                                            ║${NC}\n"
    printf "${CYAN}║             Superpowers MCP Server for Augment             ║${NC}\n"
    printf "${CYAN}║             Installation & Management Script               ║${NC}\n"
    printf "${CYAN}║                                                            ║${NC}\n"
    printf "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}\n"
    echo ""
}

# Check if installed
is_installed() {
    [ -d "$SUPERPOWERS_REPO_DIR" ] && [ -f "$MCP_SERVER_PATH" ]
}

# Add MCP server to Augment settings.json
add_to_settings() {
    if [ ! -f "$AUGMENT_SETTINGS" ]; then
        printf "${YELLOW}Warning: Settings file not found at $AUGMENT_SETTINGS${NC}\n"
        return 1
    fi

    # Create backup
    cp "$AUGMENT_SETTINGS" "${AUGMENT_SETTINGS}.backup"

    # Use Python to update JSON
    python3 - <<EOF
import json
import sys

try:
    with open("$AUGMENT_SETTINGS", "r") as f:
        settings = json.load(f)

    # Initialize mcpServers if it doesn't exist
    if "mcpServers" not in settings:
        settings["mcpServers"] = {}

    # Add superpowers server
    settings["mcpServers"]["superpowers"] = {
        "command": "node",
        "args": ["$MCP_SERVER_PATH"]
    }

    # Write back with nice formatting
    with open("$AUGMENT_SETTINGS", "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")

    sys.exit(0)
except Exception as e:
    print(f"Error updating settings: {e}", file=sys.stderr)
    sys.exit(1)
EOF

    return $?
}

# Remove MCP server from Augment settings.json
remove_from_settings() {
    if [ ! -f "$AUGMENT_SETTINGS" ]; then
        return 0  # Nothing to remove
    fi

    # Create backup
    cp "$AUGMENT_SETTINGS" "${AUGMENT_SETTINGS}.backup"

    # Use Python to update JSON
    python3 - <<EOF
import json
import sys

try:
    with open("$AUGMENT_SETTINGS", "r") as f:
        settings = json.load(f)

    # Remove superpowers server if it exists
    if "mcpServers" in settings and "superpowers" in settings["mcpServers"]:
        del settings["mcpServers"]["superpowers"]

        # Remove mcpServers key if it's now empty
        if not settings["mcpServers"]:
            del settings["mcpServers"]

    # Write back with nice formatting
    with open("$AUGMENT_SETTINGS", "w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")

    sys.exit(0)
except Exception as e:
    print(f"Error updating settings: {e}", file=sys.stderr)
    sys.exit(1)
EOF

    return $?
}

# Installation function
install_superpowers() {
    printf "${BLUE}Starting installation...${NC}\n"
    echo ""
    
    # Check prerequisites
    printf "${BLUE}Checking prerequisites...${NC}\n"
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        printf "${RED}✗ Node.js not found${NC}\n"
        echo "  Please install Node.js v18+ from https://nodejs.org/"
        exit 1
    fi

    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        printf "${RED}✗ Node.js version too old (found v${NODE_VERSION}, need v18+)${NC}\n"
        echo "  Please upgrade Node.js from https://nodejs.org/"
        exit 1
    fi
    printf "${GREEN}✓ Node.js v${NODE_VERSION} found${NC}\n"

    # Check Git
    if ! command -v git &> /dev/null; then
        printf "${RED}✗ Git not found${NC}\n"
        echo "  Please install Git from https://git-scm.com/"
        exit 1
    fi
    printf "${GREEN}✓ Git found${NC}\n"

    # Clone superpowers repository if not exists
    if [ ! -d "$SUPERPOWERS_REPO_DIR" ]; then
        echo ""
        printf "${BLUE}Cloning Superpowers repository...${NC}\n"
        echo "  Location: $SUPERPOWERS_REPO_DIR"

        mkdir -p "$(dirname "$SUPERPOWERS_REPO_DIR")"

        if ! git clone "$REPO_URL" "$SUPERPOWERS_REPO_DIR" 2>&1; then
            printf "${RED}✗ Failed to clone repository${NC}\n"
            exit 1
        fi

        printf "${GREEN}✓ Repository cloned${NC}\n"
    else
        echo ""
        printf "${GREEN}✓ Superpowers repository already exists${NC}\n"
        echo "  Location: $SUPERPOWERS_REPO_DIR"
    fi

    # Create personal skills directory
    if [ ! -d "$PERSONAL_SKILLS_DIR" ]; then
        echo ""
        printf "${BLUE}Creating personal skills directory...${NC}\n"
        mkdir -p "$PERSONAL_SKILLS_DIR"
        printf "${GREEN}✓ Personal skills directory created${NC}\n"
        echo "  Location: $PERSONAL_SKILLS_DIR"
    fi

    # Verify MCP server exists
    echo ""
    printf "${BLUE}Verifying MCP server...${NC}\n"

    if [ ! -f "$MCP_SERVER_PATH" ]; then
        printf "${RED}✗ MCP server not found at expected location${NC}\n"
        echo "  Expected: $MCP_SERVER_PATH"
        exit 1
    fi

    printf "${GREEN}✓ MCP server found${NC}\n"

    # Make MCP server executable
    chmod +x "$MCP_SERVER_PATH"

    # Install npm dependencies
    if [ ! -d "${SCRIPT_DIR}/node_modules" ]; then
        echo ""
        printf "${BLUE}Installing MCP server dependencies...${NC}\n"
        cd "$SCRIPT_DIR"
        npm install
        printf "${GREEN}✓ Dependencies installed${NC}\n"
    fi

    # Update Augment settings
    echo ""
    printf "${BLUE}Updating Augment configuration...${NC}\n"
    if add_to_settings; then
        printf "${GREEN}✓ Settings updated${NC}\n"
        echo "  Location: $AUGMENT_SETTINGS"
    else
        printf "${YELLOW}⚠ Could not automatically update settings${NC}\n"
        echo ""
        echo "Please manually add this to ~/.augment/settings.json:"
        echo ""
        printf "${BLUE}   \"mcpServers\": {${NC}\n"
        printf "${BLUE}     \"superpowers\": {${NC}\n"
        printf "${BLUE}       \"command\": \"node\",${NC}\n"
        printf "${BLUE}       \"args\": [${NC}\n"
        printf "${BLUE}         \"${MCP_SERVER_PATH}\"${NC}\n"
        printf "${BLUE}       ]${NC}\n"
        printf "${BLUE}     }${NC}\n"
        printf "${BLUE}   }${NC}\n"
    fi

    # Success!
    echo ""
    printf "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}║                                                            ║${NC}\n"
    printf "${CYAN}║                ✓ Installation Complete!                   ║${NC}\n"
    printf "${CYAN}║                                                            ║${NC}\n"
    printf "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}\n"
    echo ""
    printf "${GREEN}Next Steps:${NC}\n"
    echo ""
    echo "1. Restart Augment"
    echo ""
    echo "2. Test it by asking Augment:"
    printf "   ${BLUE}\"What skills are available?\"${NC}\n"
    echo "   You should see skills from the superpowers library"
    echo ""
    printf "${GREEN}Documentation:${NC}\n"
    echo "  • Superpowers: https://github.com/obra/superpowers"
    echo "  • Blog post: https://blog.fsck.com/2025/10/09/superpowers/"
    echo ""
    printf "${YELLOW}To update or uninstall later:${NC}\n"
    printf "  Run: ${CYAN}./install.sh update${NC} or ${CYAN}./install.sh remove${NC}\n"
    echo ""
}

# Uninstallation function
uninstall_superpowers() {
    printf "${BLUE}Starting uninstallation...${NC}\n"
    echo ""

    printf "${YELLOW}This will remove:${NC}\n"
    echo "  • Superpowers repository: $SUPERPOWERS_REPO_DIR"
    echo ""

    # Ask about personal skills
    REMOVE_SKILLS="n"
    if [ -d "$PERSONAL_SKILLS_DIR" ]; then
        printf "${YELLOW}Personal skills directory found:${NC}\n"
        echo "  $PERSONAL_SKILLS_DIR"
        echo ""
        read -p "Do you want to remove personal skills too? [y/N] " -n 1 -r
        echo ""
        REMOVE_SKILLS=$REPLY
        echo ""
    fi

    # Confirm uninstall
    read -p "Are you sure you want to uninstall? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi

    # Remove superpowers repository
    echo ""
    printf "${BLUE}Removing Superpowers repository...${NC}\n"
    rm -rf "$SUPERPOWERS_REPO_DIR"
    printf "${GREEN}✓ Superpowers repository removed${NC}\n"

    # Remove personal skills if requested
    if [[ $REMOVE_SKILLS =~ ^[Yy]$ ]]; then
        echo ""
        printf "${BLUE}Removing personal skills...${NC}\n"
        rm -rf "$PERSONAL_SKILLS_DIR"
        printf "${GREEN}✓ Personal skills removed${NC}\n"
    fi

    # Update Augment settings
    echo ""
    printf "${BLUE}Updating Augment configuration...${NC}\n"
    if remove_from_settings; then
        printf "${GREEN}✓ Settings updated${NC}\n"
        echo "  Location: $AUGMENT_SETTINGS"
    else
        printf "${YELLOW}⚠ Could not automatically update settings${NC}\n"
        echo "  Please manually remove 'superpowers' from ~/.augment/settings.json"
    fi

    # Success!
    echo ""
    printf "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}\n"
    printf "${CYAN}║                                                            ║${NC}\n"
    printf "${CYAN}║                 ✓ Uninstall Complete!                      ║${NC}\n"
    printf "${CYAN}║                                                            ║${NC}\n"
    printf "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}\n"
    echo ""
    printf "${YELLOW}Next Steps:${NC}\n"
    echo "  1. Restart Augment"
    echo ""
    printf "${BLUE}MCP server files remain at:${NC}\n"
    printf "  ${SCRIPT_DIR}\n"
    echo "  (You can delete this directory if you want)"
    echo ""
}

# Update function
update_superpowers() {
    printf "${BLUE}Updating Superpowers...${NC}\n"
    echo ""

    if [ ! -d "$SUPERPOWERS_REPO_DIR" ]; then
        printf "${RED}✗ Superpowers repository not found${NC}\n"
        printf "  Run: ${CYAN}./install.sh install${NC}\n"
        exit 1
    fi

    cd "$SUPERPOWERS_REPO_DIR"

    printf "${BLUE}Pulling latest changes from repository...${NC}\n"
    if git pull; then
        printf "${GREEN}✓ Repository updated${NC}\n"
    else
        printf "${RED}✗ Repository update failed${NC}\n"
        echo "You may need to reinstall."
        exit 1
    fi
    
    # Update MCP server dependencies if needed
    if [ -f "${SCRIPT_DIR}/package.json" ]; then
        echo ""
        printf "${BLUE}Updating MCP server dependencies...${NC}\n"
        cd "$SCRIPT_DIR"
        npm install
        printf "${GREEN}✓ Dependencies updated${NC}\n"
    fi
    
    echo ""
    printf "${GREEN}✓ Update complete${NC}\n"
    echo ""
    echo "Restart Augment to use the updated version."
    echo ""
}

# Main script logic
main() {
    show_banner

    # Parse command line argument
    ACTION="${1:-auto}"

    case "$ACTION" in
        install)
            if is_installed; then
                printf "${YELLOW}Superpowers is already installed.${NC}\n"
                echo ""
                read -p "Do you want to update it instead? [y/N] " -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    update_superpowers
                else
                    echo "Installation cancelled."
                fi
            else
                install_superpowers
            fi
            ;;

        remove|uninstall)
            if is_installed; then
                uninstall_superpowers
            else
                printf "${YELLOW}Superpowers is not installed.${NC}\n"
                echo ""
                echo "Nothing to uninstall."
            fi
            ;;

        update)
            if is_installed; then
                update_superpowers
            else
                printf "${YELLOW}Superpowers is not installed.${NC}\n"
                echo ""
                printf "Run: ${CYAN}./install.sh install${NC}\n"
            fi
            ;;

        auto)
            if is_installed; then
                printf "${GREEN}Superpowers is currently installed.${NC}\n"
                echo "  Repository: $SUPERPOWERS_REPO_DIR"
                echo "  MCP Server: $SCRIPT_DIR"
                echo ""
                echo "What would you like to do?"
                echo "  1) Update to latest version"
                echo "  2) Uninstall"
                echo "  3) Cancel"
                echo ""
                read -p "Choose [1-3]: " -n 1 -r
                echo ""
                echo ""

                case "$REPLY" in
                    1)
                        update_superpowers
                        ;;
                    2)
                        uninstall_superpowers
                        ;;
                    *)
                        echo "Cancelled."
                        ;;
                esac
            else
                printf "${YELLOW}Superpowers is not currently installed.${NC}\n"
                echo ""
                read -p "Would you like to install it? [Y/n] " -n 1 -r
                echo ""
                echo ""

                if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                    install_superpowers
                else
                    echo "Installation cancelled."
                fi
            fi
            ;;

        *)
            printf "${RED}Unknown command: $ACTION${NC}\n"
            echo ""
            echo "Usage:"
            echo "  ./install.sh          # Interactive mode"
            echo "  ./install.sh install  # Install"
            echo "  ./install.sh update   # Update"
            echo "  ./install.sh remove   # Uninstall"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
