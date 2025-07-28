#!/usr/bin/env bash

set -u

# SETUP VARS
INSTALLED_PACKAGES_FILE="$HOME/.macoststrap_installed"
DOTFILEDIR="$BASEDIR/dotfiles"

CONFIGDIR="$BASEDIR/config"
CASKFILE="$CONFIGDIR/cask-apps.conf"
BREWFILE="$CONFIGDIR/brew-packages.conf"
MASFILE="$CONFIGDIR/mas-apps.conf"
FONTSFILE="$CONFIGDIR/fonts.conf"
SPECIALFILE="$CONFIGDIR/special-packages.conf"
DIRECTFILE="$CONFIGDIR/direct-downloads.conf"

BREW=/usr/local/bin/brew

# Helper functions for package tracking
is_package_installed() {
  local package_type="$1"
  local package_name="$2"
  [[ -f "$INSTALLED_PACKAGES_FILE" ]] && grep -q "^$package_type:$package_name$" "$INSTALLED_PACKAGES_FILE"
}

generate_checklist_with_select_all() {
  local config_file="$1"
  local package_type="$2"
  local checklist_options="SELECT_ALL \"Select All\" off"
  
  if [[ -f "$config_file" ]]; then
    while IFS='|' read -r package display_name description; do
      # Skip comments and empty lines
      [[ "$package" =~ ^#.*$ ]] && continue
      [[ -z "$package" ]] && continue
      
      local status="off"
      if is_package_installed "$package_type" "$package"; then
        status="on"
        description="$description [INSTALLED]"
      fi
      
      checklist_options="$checklist_options $package \"$description\" $status"
    done < "$config_file"
  fi
  
  echo "$checklist_options"
}

generate_mas_checklist_with_select_all() {
  local checklist_options="SELECT_ALL \"Select All\" off"
  
  if [[ -f "$MASFILE" ]]; then
    while IFS='|' read -r app_id display_name description; do
      [[ "$app_id" =~ ^#.*$ ]] && continue
      [[ -z "$app_id" ]] && continue
      
      local status="off"
      local full_description="$display_name - $description"
      if is_package_installed "mas" "$app_id"; then
        status="on"
        full_description="$full_description [INSTALLED]"
      fi
      
      checklist_options="$checklist_options $app_id \"$full_description\" $status"
    done < "$MASFILE"
  fi
  
  echo "$checklist_options"
}

generate_special_checklist_with_select_all() {
  local checklist_options="SELECT_ALL \"Select All\" off"
  
  if [[ -f "$SPECIALFILE" ]]; then
    while IFS='|' read -r package display_name description install_method; do
      [[ "$package" =~ ^#.*$ ]] && continue
      [[ -z "$package" ]] && continue
      
      local status="off"
      local full_description="$display_name - $description"
      if is_package_installed "special" "$package"; then
        status="on"
        full_description="$full_description [INSTALLED]"
      fi
      
      checklist_options="$checklist_options $package \"$full_description\" $status"
    done < "$SPECIALFILE"
  fi
  
  echo "$checklist_options"
}

generate_direct_checklist_with_select_all() {
  local checklist_options="SELECT_ALL \"Select All\" off"
  
  if [[ -f "$DIRECTFILE" ]]; then
    while IFS='|' read -r name display_name description url install_cmd; do
      [[ "$name" =~ ^#.*$ ]] && continue
      [[ -z "$name" ]] && continue
      
      local status="off"
      local full_description="$display_name - $description"
      if is_package_installed "direct" "$name"; then
        status="on"
        full_description="$full_description [INSTALLED]"
      fi
      
      checklist_options="$checklist_options $name \"$full_description\" $status"
    done < "$DIRECTFILE"
  fi
  
  echo "$checklist_options"
}

show_about() {
  whiptail --title "About macOStrap" --msgbox "
  \\nmacOStrap v$VERSION
  \\n
  \\nThis tool provides some basic configs, apps and packages to get you setup and productive quickly.
  \\n
  \\nFeatures:
  - Select All option for bulk installations
  - Installation tracking and status memory
  - 7 categories of software packages
  - Interactive whiptail-based UI
  \\n
  \\nVisit the GitHub repository for more information and to report issues:
  $GITHUB_REPO_URL" 22 80
}

show_main_menu() {
  choice=$(whiptail --title "Welcome to macOStrap" --menu "\nSelect what you want to do" 0 0 0 --cancel-button Exit --ok-button Execute \
  "About macOStrap"    "Information about the macOStrap tool" \
  "" "" \
  "GUI Apps" "Install applications via homebrew cask ►"\
  "CLI Tools"      "Install command-line tools via homebrew ►" \
  "Mac App Store"      "Install apps from Mac App Store ►" \
  "Fonts"      "Install programming fonts ►" \
  "Special Packages"      "Install packages requiring special taps ►" \
  "Direct Downloads"      "Install tools via direct download ►" \
  "Terminal Config" "Install iTerm2 themes & macOS defaults ►"\
  3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ] || [ $RET -eq 255 ]; then
    # "Exit" button selected or <Esc> key pressed two times
    echo "Exiting."
    exit 0
  fi

  if [[ "$choice" == "" ]]; then
    true

  elif [[ "$choice" == *"About"* ]]; then
    show_about

  elif [[ "$choice" == *"GUI Apps"* ]]; then
    show_cask_selection

  elif [[ "$choice" == *"CLI Tools"* ]]; then
    show_brew_selection

  elif [[ "$choice" == *"Mac App Store"* ]]; then
    show_mas_selection

  elif [[ "$choice" == *"Fonts"* ]]; then
    show_fonts_selection

  elif [[ "$choice" == *"Special Packages"* ]]; then
    show_special_packages_selection

  elif [[ "$choice" == *"Direct Downloads"* ]]; then
    show_direct_downloads_selection

  elif [[ "$choice" == *"Terminal Config"* ]]; then
    terminalConfig=$(whiptail --title "Terminal Configuration" --menu "\nSelect the configuration you want to install:\n\n[enter] = install\n[tab] = switch to Buttons / List" 0 0 0 --cancel-button Back --ok-button Install \
    "iterm2    "    "Install iTerm2 themes & config"\
    "mac defaults    "    "Change mac defaults (e.g. show the ~/Library/ Folder)"\
    3>&1 1>&2 2>&3)
    if [ $? -eq 1 ] || [ $? -eq 255 ]; then return 0; fi
    case "$terminalConfig" in
      iterm2\ *) sh "$BASEDIR/mac/iterm2_install.sh";;
      mac\ *) sh "$BASEDIR/mac/mac_install.sh";;
      "") return ;;
      *) whiptail --msgbox "A not supported option was selected (probably a programming error):\\n  \"$terminalConfig\"" 8 80 ;;
    esac
  fi
}

# Legacy function for backwards compatibility
generate_checklist_from_config() {
  local config_file="$1"
  local checklist_options=""
  
  if [[ -f "$config_file" ]]; then
    while IFS='|' read -r package display_name description; do
      # Skip comments and empty lines
      [[ "$package" =~ ^#.*$ ]] && continue
      [[ -z "$package" ]] && continue
      
      local status="off"
      if [[ "$config_file" == *"cask-apps.conf" ]] && is_package_installed "cask" "$package"; then
        status="on"
        description="$description [INSTALLED]"
      elif [[ "$config_file" == *"brew-packages.conf" ]] && is_package_installed "brew" "$package"; then
        status="on"
        description="$description [INSTALLED]"
      elif [[ "$config_file" == *"fonts.conf" ]] && is_package_installed "font" "$package"; then
        status="on"
        description="$description [INSTALLED]"
      fi
      
      checklist_options="$checklist_options $package \"$description\" $status"
    done < "$config_file"
  fi
  
  echo "$checklist_options"
}

show_cask_selection() {
  local options=$(generate_checklist_with_select_all "$CASKFILE" "cask")
  
  if [[ -z "$options" ]]; then
    whiptail --msgbox "No cask applications configured." 8 50
    return 0
  fi
  
  eval "apps=\$(whiptail --separate-output --title \"GUI Applications\" --checklist \"\\nSelect the apps you want to install:\\n\\n[spacebar] = toggle on/off\\n[tab] = switch to Buttons / List\" 0 0 0 --cancel-button Back --ok-button Install $options 3>&1 1>&2 2>&3)"
  
  if [ $? -eq 1 ] || [ $? -eq 255 ]; then return 0; fi
  
  if [[ "${#apps}" > 0 ]]; then
    # Check if SELECT_ALL was chosen
    if echo "$apps" | grep -q "SELECT_ALL"; then
      # Install all packages from config file
      while IFS='|' read -r package display_name description; do
        [[ "$package" =~ ^#.*$ ]] && continue
        [[ -z "$package" ]] && continue
        if ! is_package_installed "cask" "$package"; then
          install_cask_app "$package"
        fi
      done < "$CASKFILE"
    else
      # Install selected packages
      while read -r app; do
        [[ -z "$app" ]] && continue
        [[ "$app" == "SELECT_ALL" ]] && continue
        install_cask_app "$app"
      done <<< "$apps"
    fi
  fi
}

show_brew_selection() {
  local options=$(generate_checklist_with_select_all "$BREWFILE" "brew")
  
  if [[ -z "$options" ]]; then
    whiptail --msgbox "No brew packages configured." 8 50
    return 0
  fi
  
  eval "packages=\$(whiptail --separate-output --title \"CLI Tools\" --checklist \"\\nSelect the packages you want to install:\\n\\n[spacebar] = toggle on/off\\n[tab] = switch to Buttons / List\" 0 0 0 --cancel-button Back --ok-button Install $options 3>&1 1>&2 2>&3)"
  
  if [ $? -eq 1 ] || [ $? -eq 255 ]; then return 0; fi
  
  if [[ "${#packages}" > 0 ]]; then
    # Check if SELECT_ALL was chosen
    if echo "$packages" | grep -q "SELECT_ALL"; then
      # Install all packages from config file
      while IFS='|' read -r package display_name description; do
        [[ "$package" =~ ^#.*$ ]] && continue
        [[ -z "$package" ]] && continue
        if ! is_package_installed "brew" "$package"; then
          install_brew_package "$package"
        fi
      done < "$BREWFILE"
    else
      # Install selected packages
      while read -r package; do
        [[ -z "$package" ]] && continue
        [[ "$package" == "SELECT_ALL" ]] && continue
        install_brew_package "$package"
      done <<< "$packages"
    fi
  fi
}

show_mas_selection() {
  mas_install
  
  local options=$(generate_mas_checklist_with_select_all)
  
  if [[ -z "$options" ]]; then
    whiptail --msgbox "No Mac App Store applications configured." 8 50
    return 0
  fi
  
  eval "apps=\$(whiptail --separate-output --title \"Mac App Store\" --checklist \"\\nSelect the apps you want to install:\\n\\n[spacebar] = toggle on/off\\n[tab] = switch to Buttons / List\" 0 0 0 --cancel-button Back --ok-button Install $options 3>&1 1>&2 2>&3)"
  
  if [ $? -eq 1 ] || [ $? -eq 255 ]; then return 0; fi
  
  if [[ "${#apps}" > 0 ]]; then
    # Check if SELECT_ALL was chosen
    if echo "$apps" | grep -q "SELECT_ALL"; then
      # Install all apps from config file
      while IFS='|' read -r app_id display_name description; do
        [[ "$app_id" =~ ^#.*$ ]] && continue
        [[ -z "$app_id" ]] && continue
        if ! is_package_installed "mas" "$app_id"; then
          install_mas_app "$app_id" "$display_name"
        fi
      done < "$MASFILE"
    else
      # Install selected apps
      while read -r app_id; do
        [[ -z "$app_id" ]] && continue
        [[ "$app_id" == "SELECT_ALL" ]] && continue
        # Get display name from config
        local display_name=$(grep "^$app_id|" "$MASFILE" | cut -d'|' -f2)
        install_mas_app "$app_id" "$display_name"
      done <<< "$apps"
    fi
  fi
}

show_fonts_selection() {
  local options=$(generate_checklist_with_select_all "$FONTSFILE" "font")
  
  if [[ -z "$options" ]]; then
    whiptail --msgbox "No fonts configured." 8 50
    return 0
  fi
  
  eval "fonts=\$(whiptail --separate-output --title \"Fonts\" --checklist \"\\nSelect the fonts you want to install:\\n\\n[spacebar] = toggle on/off\\n[tab] = switch to Buttons / List\" 0 0 0 --cancel-button Back --ok-button Install $options 3>&1 1>&2 2>&3)"
  
  if [ $? -eq 1 ] || [ $? -eq 255 ]; then return 0; fi
  
  if [[ "${#fonts}" > 0 ]]; then
    # Check if SELECT_ALL was chosen
    if echo "$fonts" | grep -q "SELECT_ALL"; then
      # Install all fonts from config file
      while IFS='|' read -r package display_name description; do
        [[ "$package" =~ ^#.*$ ]] && continue
        [[ -z "$package" ]] && continue
        if ! is_package_installed "font" "$package"; then
          install_font "$package"
        fi
      done < "$FONTSFILE"
    else
      # Install selected fonts
      while read -r font; do
        [[ -z "$font" ]] && continue
        [[ "$font" == "SELECT_ALL" ]] && continue
        install_font "$font"
      done <<< "$fonts"
    fi
  fi
}

show_special_packages_selection() {
  local options=$(generate_special_checklist_with_select_all)
  
  if [[ -z "$options" ]]; then
    whiptail --msgbox "No special packages configured." 8 50
    return 0
  fi
  
  eval "packages=\$(whiptail --separate-output --title \"Special Packages\" --checklist \"\\nSelect the packages you want to install:\\n\\n[spacebar] = toggle on/off\\n[tab] = switch to Buttons / List\" 0 0 0 --cancel-button Back --ok-button Install $options 3>&1 1>&2 2>&3)"
  
  if [ $? -eq 1 ] || [ $? -eq 255 ]; then return 0; fi
  
  if [[ "${#packages}" > 0 ]]; then
    # Check if SELECT_ALL was chosen
    if echo "$packages" | grep -q "SELECT_ALL"; then
      # Install all packages from config file
      while IFS='|' read -r package display_name description install_method; do
        [[ "$package" =~ ^#.*$ ]] && continue
        [[ -z "$package" ]] && continue
        if ! is_package_installed "special" "$package"; then
          install_special_package "$package" "$display_name" "$description" "$install_method"
        fi
      done < "$SPECIALFILE"
    else
      # Install selected packages
      while read -r package; do
        [[ -z "$package" ]] && continue
        [[ "$package" == "SELECT_ALL" ]] && continue
        # Get install details from config
        local line=$(grep "^$package|" "$SPECIALFILE")
        local display_name=$(echo "$line" | cut -d'|' -f2)
        local description=$(echo "$line" | cut -d'|' -f3)
        local install_cmd=$(echo "$line" | cut -d'|' -f4)
        install_special_package "$package" "$display_name" "$description" "$install_cmd"
      done <<< "$packages"
    fi
  fi
}

show_direct_downloads_selection() {
  local options=$(generate_direct_checklist_with_select_all)
  
  if [[ -z "$options" ]]; then
    whiptail --msgbox "No direct downloads configured." 8 50
    return 0
  fi
  
  eval "downloads=\$(whiptail --separate-output --title \"Direct Downloads\" --checklist \"\\nSelect the tools you want to install:\\n\\n[spacebar] = toggle on/off\\n[tab] = switch to Buttons / List\" 0 0 0 --cancel-button Back --ok-button Install $options 3>&1 1>&2 2>&3)"
  
  if [ $? -eq 1 ] || [ $? -eq 255 ]; then return 0; fi
  
  if [[ "${#downloads}" > 0 ]]; then
    # Check if SELECT_ALL was chosen
    if echo "$downloads" | grep -q "SELECT_ALL"; then
      # Install all downloads from config file
      while IFS='|' read -r name display_name description url install_cmd; do
        [[ "$name" =~ ^#.*$ ]] && continue
        [[ -z "$name" ]] && continue
        if ! is_package_installed "direct" "$name"; then
          install_direct_download "$name" "$display_name" "$description" "$url" "$install_cmd"
        fi
      done < "$DIRECTFILE"
    else
      # Install selected downloads
      while read -r name; do
        [[ -z "$name" ]] && continue
        [[ "$name" == "SELECT_ALL" ]] && continue
        # Get download details from config
        local line=$(grep "^$name|" "$DIRECTFILE")
        local display_name=$(echo "$line" | cut -d'|' -f2)
        local description=$(echo "$line" | cut -d'|' -f3)
        local url=$(echo "$line" | cut -d'|' -f4)
        local install_cmd=$(echo "$line" | cut -d'|' -f5)
        install_direct_download "$name" "$display_name" "$description" "$url" "$install_cmd"
      done <<< "$downloads"
    fi
  fi
}