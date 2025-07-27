#!/bin/bash

# macOStrap Bootstrap Script
# Usage: curl -fsSL https://raw.githubusercontent.com/ricardorodrigues-ca/macOStrap/refs/heads/master/bootstrap.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project configuration
REPO_URL="https://github.com/ricardorodrigues-ca/macOStrap.git"
INSTALL_DIR="$HOME/.macOStrap"
TEMP_DIR="/tmp/macOStrap-$$"

print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════╗"
    echo "║            macOStrap Setup            ║"
    echo "║     Fast macOS Configuration Tool     ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This script is designed for macOS only. Detected: $(uname)"
    fi
    
    local version=$(sw_vers -productVersion)
    local major_version=$(echo "$version" | cut -d. -f1)
    
    if [[ $major_version -lt 11 ]]; then
        log_error "macOStrap requires macOS 11.0+ (Big Sur). Current version: $version"
    fi
    
    log_success "macOS $version detected - compatible"
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        log_error "Git is required but not installed. Please install Xcode Command Line Tools first: xcode-select --install"
    fi
    
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed."
    fi
    
    log_success "All dependencies found"
}

cleanup_previous_install() {
    if [[ -d "$INSTALL_DIR" ]]; then
        log_warn "Previous installation found at $INSTALL_DIR"
        echo -n "Remove previous installation? [y/N]: "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            rm -rf "$INSTALL_DIR"
            log_success "Previous installation removed"
        else
            log_error "Cannot proceed with existing installation. Please remove $INSTALL_DIR manually."
        fi
    fi
}

download_macoststrap() {
    log_info "Downloading macOStrap..."
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    
    # Clone repository
    if git clone --depth 1 "$REPO_URL" "$TEMP_DIR" &> /dev/null; then
        log_success "Repository downloaded successfully"
    else
        log_error "Failed to download repository from $REPO_URL"
    fi
    
    # Move to install directory
    mv "$TEMP_DIR" "$INSTALL_DIR"
    log_success "Installed to $INSTALL_DIR"
}

set_permissions() {
    log_info "Setting executable permissions..."
    chmod +x "$INSTALL_DIR/install.sh"
    chmod +x "$INSTALL_DIR/functions/"*.sh
    chmod +x "$INSTALL_DIR/mac/"*.sh
    log_success "Permissions set"
}

launch_installer() {
    log_info "Launching macOStrap installer..."
    echo
    
    cd "$INSTALL_DIR"
    exec ./install.sh
}

main() {
    print_banner
    
    echo "This script will download and install macOStrap, a tool for quickly"
    echo "setting up your macOS development environment."
    echo
    echo -n "Continue with installation? [Y/n]: "
    read -r response
    
    if [[ "$response" =~ ^[Nn]$ ]]; then
        echo "Installation cancelled."
        exit 0
    fi
    
    echo
    log_info "Starting macOStrap bootstrap..."
    
    check_macos
    check_dependencies
    cleanup_previous_install
    download_macoststrap
    set_permissions
    launch_installer
}

# Trap cleanup on exit
trap 'rm -rf "$TEMP_DIR" 2>/dev/null || true' EXIT

# Run main function
main "$@"