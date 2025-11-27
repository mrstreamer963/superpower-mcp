#\!/bin/bash

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
REPO_URL="https://github.com/obra/superpowers.git"

# Detect where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MCP_SERVER_PATH="${SCRIPT_DIR}/superpowers-mcp.js"

# Banner
show_banner() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}║         Superpowers MCP Server for Augment                ║${NC}"
    echo -e "${CYAN}║         Installation & Management Script                  ║${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Check if installed
is_installed() {
    [ -d "$SUPERPOWERS_REPO_DIR" ] && [ -f "$MCP_SERVER_PATH" ]
}

# Installation function
install_superpowers() {
    echo -e "${BLUE}Starting installation...${NC}"
    echo ""
    
    # Check prerequisites
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    # Check Node.js
    if \! command -v node &> /dev/null; then
        echo -e "${RED}✗ Node.js not found${NC}"
        echo "  Please install Node.js v18+ from https://nodejs.org/"
        exit 1
    fi
    
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        echo -e "${RED}✗ Node.js version too old (found v${NODE_VERSION}, need v18+)${NC}"
        echo "  Please upgrade Node.js from https://nodejs.org/"
        exit 1
    fi
    echo -e "${GREEN}✓ Node.js v${NODE_VERSION} found${NC}"
    
    # Check Git
    if \! command -v git &> /dev/null; then
        echo -e "${RED}✗ Git not found${NC}"
        echo "  Please install Git from https://git-scm.com/"
        exit 1
    fi
    echo -e "${GREEN}✓ Git found${NC}"
    
    # Clone superpowers repository if not exists
    if [ \! -d "$SUPERPOWERS_REPO_DIR" ]; then
        echo ""
        echo -e "${BLUE}Cloning Superpowers repository...${NC}"
        echo "  Location: $SUPERPOWERS_REPO_DIR"
        
        mkdir -p "$(dirname "$SUPERPOWERS_REPO_DIR")"
        
        if \! git clone "$REPO_URL" "$SUPERPOWERS_REPO_DIR" 2>&1; then
            echo -e "${RED}✗ Failed to clone repository${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}✓ Repository cloned${NC}"
    else
        echo ""
        echo -e "${GREEN}✓ Superpowers repository already exists${NC}"
        echo "  Location: $SUPERPOWERS_REPO_DIR"
    fi
    
    # Create personal skills directory
    if [ \! -d "$PERSONAL_SKILLS_DIR" ]; then
        echo ""
        echo -e "${BLUE}Creating personal skills directory...${NC}"
        mkdir -p "$PERSONAL_SKILLS_DIR"
        echo -e "${GREEN}✓ Personal skills directory created${NC}"
        echo "  Location: $PERSONAL_SKILLS_DIR"
    fi
    
    # Verify MCP server exists
    echo ""
    echo -e "${BLUE}Verifying MCP server...${NC}"
    
    if [ \! -f "$MCP_SERVER_PATH" ]; then
        echo -e "${RED}✗ MCP server not found at expected location${NC}"
        echo "  Expected: $MCP_SERVER_PATH"
        exit 1
    fi
    
    echo -e "${GREEN}✓ MCP server found${NC}"
    
    # Make MCP server executable
    chmod +x "$MCP_SERVER_PATH"
    
    # Install npm dependencies
    if [ \! -d "${SCRIPT_DIR}/node_modules" ]; then
        echo ""
        echo -e "${BLUE}Installing MCP server dependencies...${NC}"
        cd "$SCRIPT_DIR"
        npm install
        echo -e "${GREEN}✓ Dependencies installed${NC}"
    fi
    
    # Success\!
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}║              ✓ Installation Complete\!                     ║${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Next Steps:${NC}"
    echo ""
    echo "1. Add this MCP server to your Augment configuration:"
    echo ""
    echo "   ${YELLOW}Edit ~/.augment/settings.json and add:${NC}"
    echo ""
    echo -e "${BLUE}   \"mcpServers\": {${NC}"
    echo -e "${BLUE}     \"superpowers\": {${NC}"
    echo -e "${BLUE}       \"command\": \"node\",${NC}"
    echo -e "${BLUE}       \"args\": [${NC}"
    echo -e "${BLUE}         \"${MCP_SERVER_PATH}\"${NC}"
    echo -e "${BLUE}       ]${NC}"
    echo -e "${BLUE}     }${NC}"
    echo -e "${BLUE}   }${NC}"
    echo ""
    echo "2. Restart Augment"
    echo ""
    echo "3. Test it by asking Augment:"
    echo "   ${BLUE}\"What skills are available?\"${NC}"
    echo "   You should see skills from the superpowers library"
    echo ""
    echo -e "${GREEN}Documentation:${NC}"
    echo "  • Superpowers: https://github.com/obra/superpowers"
    echo "  • Blog post: https://blog.fsck.com/2025/10/09/superpowers/"
    echo ""
    echo -e "${YELLOW}To update or uninstall later:${NC}"
    echo "  Run: ${CYAN}./install.sh update${NC} or ${CYAN}./install.sh remove${NC}"
    echo ""
}

# Uninstallation function
uninstall_superpowers() {
    echo -e "${BLUE}Starting uninstallation...${NC}"
    echo ""

    echo -e "${YELLOW}This will remove:${NC}"
    echo "  • Superpowers repository: $SUPERPOWERS_REPO_DIR"
    echo ""

    # Ask about personal skills
    REMOVE_SKILLS="n"
    if [ -d "$PERSONAL_SKILLS_DIR" ]; then
        echo -e "${YELLOW}Personal skills directory found:${NC}"
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
    if [[ \! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstall cancelled."
        exit 0
    fi

    # Remove superpowers repository
    echo ""
    echo -e "${BLUE}Removing Superpowers repository...${NC}"
    rm -rf "$SUPERPOWERS_REPO_DIR"
    echo -e "${GREEN}✓ Superpowers repository removed${NC}"

    # Remove personal skills if requested
    if [[ $REMOVE_SKILLS =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${BLUE}Removing personal skills...${NC}"
        rm -rf "$PERSONAL_SKILLS_DIR"
        echo -e "${GREEN}✓ Personal skills removed${NC}"
    fi

    # Success\!
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}║            ✓ Uninstall Complete\!                          ║${NC}"
    echo -e "${CYAN}║                                                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Don't forget to:${NC}"
    echo "  1. Remove 'superpowers' from ~/.augment/settings.json"
    echo "  2. Restart Augment"
    echo ""
    echo -e "${BLUE}MCP server files remain at:${NC}"
    echo "  ${SCRIPT_DIR}"
    echo "  (You can delete this directory if you want)"
    echo ""
}

# Update function
update_superpowers() {
    echo -e "${BLUE}Updating Superpowers...${NC}"
    echo ""

    if [ \! -d "$SUPERPOWERS_REPO_DIR" ]; then
        echo -e "${RED}✗ Superpowers repository not found${NC}"
        echo "  Run: ${CYAN}./install.sh install${NC}"
        exit 1
    fi

    cd "$SUPERPOWERS_REPO_DIR"

    echo -e "${BLUE}Pulling latest changes from repository...${NC}"
    if git pull; then
        echo -e "${GREEN}✓ Repository updated${NC}"
    else
        echo -e "${RED}✗ Repository update failed${NC}"
        echo "You may need to reinstall."
        exit 1
    fi
    
    # Update MCP server dependencies if needed
    if [ -f "${SCRIPT_DIR}/package.json" ]; then
        echo ""
        echo -e "${BLUE}Updating MCP server dependencies...${NC}"
        cd "$SCRIPT_DIR"
        npm install
        echo -e "${GREEN}✓ Dependencies updated${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}✓ Update complete${NC}"
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
                echo -e "${YELLOW}Superpowers is already installed.${NC}"
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
                echo -e "${YELLOW}Superpowers is not installed.${NC}"
                echo ""
                echo "Nothing to uninstall."
            fi
            ;;

        update)
            if is_installed; then
                update_superpowers
            else
                echo -e "${YELLOW}Superpowers is not installed.${NC}"
                echo ""
                echo "Run: ${CYAN}./install.sh install${NC}"
            fi
            ;;

        auto)
            if is_installed; then
                echo -e "${GREEN}Superpowers is currently installed.${NC}"
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
                echo -e "${YELLOW}Superpowers is not currently installed.${NC}"
                echo ""
                read -p "Would you like to install it? [Y/n] " -n 1 -r
                echo ""
                echo ""

                if [[ \! $REPLY =~ ^[Nn]$ ]]; then
                    install_superpowers
                else
                    echo "Installation cancelled."
                fi
            fi
            ;;

        *)
            echo -e "${RED}Unknown command: $ACTION${NC}"
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
