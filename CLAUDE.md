# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
macOStrap is a modernized macOS system setup and configuration tool that provides a whiptail-based UI for installing homebrew packages, cask applications, Mac App Store apps, fonts, and development tools. It's designed for quickly bootstrapping a new macOS development environment with a single curl command.

## Running the Tool
- **Bootstrap installation**: `curl -fsSL https://raw.githubusercontent.com/ricardorodrigues-ca/macOStrap/refs/heads/master/bootstrap.sh | bash`
- **Local installation**: `./install.sh` - This installs homebrew, whiptail, and launches the interactive UI
- **Platform requirement**: macOS 11.0+ (Big Sur) - checked in `src/osx.sh:16`

## Architecture and Key Components

### Core Structure
- `bootstrap.sh` - Remote bootstrap script for one-curl installation
- `install.sh` - Entry point that detects platform and sources `src/osx.sh`
- `src/osx.sh` - Main orchestrator that sources all function scripts and starts the UI
- `functions/` - Modular bash functions:
  - `installer.sh` - Installation functions for homebrew, whiptail, mas, and package installers
  - `menu.sh` - Whiptail UI menus and user interaction logic with config file integration
  - `utils.sh` - Utility functions for file operations and user confirmation
- `config/` - Configuration files defining software packages:
  - `cask-apps.conf` - GUI applications via homebrew cask
  - `brew-packages.conf` - Command-line tools and libraries
  - `mas-apps.conf` - Mac App Store applications
  - `fonts.conf` - Programming fonts
  - `special-packages.conf` - Packages requiring special taps
  - `direct-downloads.conf` - Tools installed via direct download/npm
- `dotfiles/` - Configuration files (legacy zsh configs)
- `mac/` - macOS-specific configurations including iTerm2 themes and system preferences

### Installation Categories
The modernized tool organizes installations into seven main categories:
1. **GUI Apps** - Applications via homebrew cask (modern editors, browsers, tools)
2. **CLI Tools** - Command-line tools via homebrew (extensive list including dev tools)
3. **Mac App Store** - Apps installed via `mas` (PastePal, Espanso, Clocker)
4. **Fonts** - Programming fonts (Hack Nerd Font)
5. **Special Packages** - Packages requiring special taps (LibreWolf, Ghostty, etc.)
6. **Direct Downloads** - Tools via direct download or npm (AWS CLI, Claude Code, etc.)
7. **Terminal Config** - iTerm2 themes and macOS defaults

### Key Functions
- `homebrew_install()` - Installs homebrew using the official bash installer (`functions/installer.sh:3`)
- `whiptail_install()` - Installs newt (whiptail) for the UI (`functions/installer.sh:14`)
- `mas_install()` - Installs Mac App Store CLI (`functions/installer.sh:29`)
- `show_main_menu()` - Primary navigation interface (`functions/menu.sh:26`)
- `install_*()` functions - Specialized installers for each package type
- `generate_checklist_from_config()` - Dynamically builds whiptail menus from config files

### Configuration File Format
All `.conf` files use pipe-delimited format:
- `cask-apps.conf`: `package_name|Display Name|Description`
- `brew-packages.conf`: `package_name|Display Name|Description`
- `mas-apps.conf`: `app_id|Display Name|Description`
- `fonts.conf`: `package_name|Display Name|Description`
- `special-packages.conf`: `package_name|Display Name|Description|Installation Method`
- `direct-downloads.conf`: `name|Display Name|Description|URL|Install Command`

### Code Patterns
- All bash scripts use `#!/usr/bin/env bash` or `#!/bin/bash`
- Functions are modular and sourced dynamically
- Configuration-driven package management using pipe-delimited files
- Error handling uses return codes and conditional checks
- User interaction relies heavily on whiptail for consistent UI
- Installation verification checks if tools are already present before installing
- Dynamic menu generation from configuration files

## Development Notes
- No traditional build/test/lint commands - this is a pure bash script project
- Testing would involve running the bootstrap script in a clean macOS environment
- The codebase expects to run on macOS Darwin platform only (11.0+)
- External dependencies: homebrew, whiptail (newt), git, mas (for App Store)
- Package lists are maintained in separate config files for easy updates
- Bootstrap script enables one-command installation from any clean macOS system