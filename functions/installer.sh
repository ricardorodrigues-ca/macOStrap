#!/usr/bin/env bash

homebrew_install() {
  echo "Installing homebrew..."
  if [ ! -f /usr/local/bin/brew ]; then
    #ruby -e "$(\curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    brew tap homebrew/cask-versions
  else
    echo "Homebrew already installed. So far, so good."
  fi
}

whiptail_install() {
  echo "Installing whiptail..."
  if [ ! -f /usr/local/bin/whiptail ]; then
    brew install newt
  else
    # Test whiptail version
    whiptail -v > /dev/null 2>/dev/null
    if [[ $? -ne 0 ]]; then
      brew reinstall newt
    else
      echo "Whiptail already installed. Going on..."
    fi
  fi
}

mas_install() {
  echo "Installing Mac App Store CLI..."
  if ! command -v mas &> /dev/null; then
    brew install mas
  else
    echo "mas already installed. Going on..."
  fi
}

install_from_config() {
  local config_file="$1"
  local install_function="$2"
  
  if [[ -f "$config_file" ]]; then
    while IFS='|' read -r package display_name description; do
      # Skip comments and empty lines
      [[ "$package" =~ ^#.*$ ]] && continue
      [[ -z "$package" ]] && continue
      
      $install_function "$package" "$display_name" "$description"
    done < "$config_file"
  fi
}

install_cask_app() {
  local package="$1"
  echo "Installing $package via homebrew cask..."
  brew install --cask "$package" 2>/dev/null || echo "Failed to install $package"
}

install_brew_package() {
  local package="$1"
  echo "Installing $package via homebrew..."
  brew install "$package" 2>/dev/null || echo "Failed to install $package"
}

install_mas_app() {
  local app_id="$1"
  local display_name="$2"
  echo "Installing $display_name via Mac App Store..."
  mas install "$app_id" 2>/dev/null || echo "Failed to install $display_name"
}

install_font() {
  local package="$1"
  echo "Installing $package..."
  brew install --cask "$package" 2>/dev/null || echo "Failed to install $package"
}

install_special_package() {
  local package="$1"
  local display_name="$2"
  local description="$3"
  local install_cmd="$4"
  echo "Installing $display_name..."
  eval "$install_cmd" 2>/dev/null || echo "Failed to install $display_name"
}

install_direct_download() {
  local name="$1"
  local display_name="$2" 
  local description="$3"
  local url="$4"
  local install_cmd="$5"
  
  echo "Installing $display_name..."
  
  if [[ "$install_cmd" == npm* ]]; then
    # For npm packages, just run the install command
    eval "$install_cmd" 2>/dev/null || echo "Failed to install $display_name"
  else
    # For downloads, get the file first
    local filename=$(basename "$url")
    curl -L -o "/tmp/$filename" "$url" 2>/dev/null
    if [[ -f "/tmp/$filename" ]]; then
      cd /tmp && eval "$install_cmd" 2>/dev/null || echo "Failed to install $display_name"
      rm -f "/tmp/$filename"
    else
      echo "Failed to download $display_name"
    fi
  fi
}
