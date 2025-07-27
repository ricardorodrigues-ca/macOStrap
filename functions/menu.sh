#!/usr/bin/env bash

set -u

# SETUP VARS
DOTFILEDIR="$BASEDIR/dotfiles"

CONFIGDIR="$BASEDIR/config"
CASKFILE="$CONFIGDIR/cask-apps.conf"
BREWFILE="$CONFIGDIR/brew-packages.conf"
MASFILE="$CONFIGDIR/mas-apps.conf"
FONTSFILE="$CONFIGDIR/fonts.conf"
SPECIALFILE="$CONFIGDIR/special-packages.conf"
DIRECTFILE="$CONFIGDIR/direct-downloads.conf"

BREW=/usr/local/bin/brew

show_about() {
  whiptail --title "About macOStrap" --msgbox "
  \\nThis tool provides some basic configs, apps and packages to get you setup and productive quickly.
  \\n
  \\nVisit the following github repo for more information and feel free to leave feedback and file an issue in case you encounter any bugs:
  - Git Repo: $GITHUB_REPO_URL" 20 80
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

generate_checklist_from_config() {
  local config_file="$1"
  local checklist_options=""
  
  if [[ -f "$config_file" ]]; then
    while IFS='|' read -r package display_name description; do
      # Skip comments and empty lines
      [[ "$package" =~ ^#.*$ ]] && continue
      [[ -z "$package" ]] && continue
      
      checklist_options="$checklist_options $package \"$description\" off"
    done < "$config_file"
  fi
  
  echo "$checklist_options"
}

show_cask_selection() {
  local options=$(generate_checklist_from_config "$CASKFILE")
  
  if [[ -z "$options" ]]; then
    whiptail --msgbox "No cask applications configured." 8 50
    return 0
  fi
  
  eval "apps=\$(whiptail --separate-output --title \"GUI Applications\" --checklist \"\\nSelect the apps you want to install:\\n\\n[spacebar] = toggle on/off\\n[tab] = switch to Buttons / List\" 0 0 0 --cancel-button Back --ok-button Install $options 3>&1 1>&2 2>&3)"
  
  if [ $? -eq 1 ] || [ $? -eq 255 ]; then return 0; fi
  
  if [[ "${#apps}" > 0 ]]; then
    while read -r app; do
      [[ -z "$app" ]] && continue
      install_cask_app "$app"
    done <<< "$apps"
  fi
}

show_brew_selection() {
  local options=$(generate_checklist_from_config "$BREWFILE")
  
  if [[ -z "$options" ]]; then
    whiptail --msgbox "No brew packages configured." 8 50
    return 0
  fi
  
  eval "packages=\$(whiptail --separate-output --title \"CLI Tools\" --checklist \"\\nSelect the packages you want to install:\\n\\n[spacebar] = toggle on/off\\n[tab] = switch to Buttons / List\" 0 0 0 --cancel-button Back --ok-button Install $options 3>&1 1>&2 2>&3)"
  
  if [ $? -eq 1 ] || [ $? -eq 255 ]; then return 0; fi
  
  if [[ "${#packages}" > 0 ]]; then
    while read -r package; do
      [[ -z "$package" ]] && continue
      install_brew_package "$package"
    done <<< "$packages"
  fi
}

show_mas_selection() {
  mas_install
  
  local options=""
  if [[ -f "$MASFILE" ]]; then
    while IFS='|' read -r app_id display_name description; do
      [[ "$app_id" =~ ^#.*$ ]] && continue
      [[ -z "$app_id" ]] && continue
      
      options="$options $app_id \"$display_name - $description\" off"
    done < "$MASFILE"
  fi
  
  if [[ -z "$options" ]]; then
    whiptail --msgbox "No Mac App Store applications configured." 8 50
    return 0
  fi
  
  eval "apps=\$(whiptail --separate-output --title \"Mac App Store\" --checklist \"\\nSelect the apps you want to install:\\n\\n[spacebar] = toggle on/off\\n[tab] = switch to Buttons / List\" 0 0 0 --cancel-button Back --ok-button Install $options 3>&1 1>&2 2>&3)"
  
  if [ $? -eq 1 ] || [ $? -eq 255 ]; then return 0; fi
  
  if [[ "${#apps}" > 0 ]]; then
    while read -r app_id; do
      [[ -z "$app_id" ]] && continue
      # Get display name from config
      local display_name=$(grep "^$app_id|" "$MASFILE" | cut -d'|' -f2)
      install_mas_app "$app_id" "$display_name"
    done <<< "$apps"
  fi
}

show_fonts_selection() {
  local options=$(generate_checklist_from_config "$FONTSFILE")
  
  if [[ -z "$options" ]]; then
    whiptail --msgbox "No fonts configured." 8 50
    return 0
  fi
  
  eval "fonts=\$(whiptail --separate-output --title \"Fonts\" --checklist \"\\nSelect the fonts you want to install:\\n\\n[spacebar] = toggle on/off\\n[tab] = switch to Buttons / List\" 0 0 0 --cancel-button Back --ok-button Install $options 3>&1 1>&2 2>&3)"
  
  if [ $? -eq 1 ] || [ $? -eq 255 ]; then return 0; fi
  
  if [[ "${#fonts}" > 0 ]]; then
    while read -r font; do
      [[ -z "$font" ]] && continue
      install_font "$font"
    done <<< "$fonts"
  fi
}

show_special_packages_selection() {
  local options=""
  if [[ -f "$SPECIALFILE" ]]; then
    while IFS='|' read -r package display_name description install_method; do
      [[ "$package" =~ ^#.*$ ]] && continue
      [[ -z "$package" ]] && continue
      
      options="$options $package \"$display_name - $description\" off"
    done < "$SPECIALFILE"
  fi
  
  if [[ -z "$options" ]]; then
    whiptail --msgbox "No special packages configured." 8 50
    return 0
  fi
  
  eval "packages=\$(whiptail --separate-output --title \"Special Packages\" --checklist \"\\nSelect the packages you want to install:\\n\\n[spacebar] = toggle on/off\\n[tab] = switch to Buttons / List\" 0 0 0 --cancel-button Back --ok-button Install $options 3>&1 1>&2 2>&3)"
  
  if [ $? -eq 1 ] || [ $? -eq 255 ]; then return 0; fi
  
  if [[ "${#packages}" > 0 ]]; then
    while read -r package; do
      [[ -z "$package" ]] && continue
      # Get install details from config
      local line=$(grep "^$package|" "$SPECIALFILE")
      local display_name=$(echo "$line" | cut -d'|' -f2)
      local description=$(echo "$line" | cut -d'|' -f3)
      local install_cmd=$(echo "$line" | cut -d'|' -f4)
      install_special_package "$package" "$display_name" "$description" "$install_cmd"
    done <<< "$packages"
  fi
}

show_direct_downloads_selection() {
  local options=""
  if [[ -f "$DIRECTFILE" ]]; then
    while IFS='|' read -r name display_name description url install_cmd; do
      [[ "$name" =~ ^#.*$ ]] && continue
      [[ -z "$name" ]] && continue
      
      options="$options $name \"$display_name - $description\" off"
    done < "$DIRECTFILE"
  fi
  
  if [[ -z "$options" ]]; then
    whiptail --msgbox "No direct downloads configured." 8 50
    return 0
  fi
  
  eval "downloads=\$(whiptail --separate-output --title \"Direct Downloads\" --checklist \"\\nSelect the tools you want to install:\\n\\n[spacebar] = toggle on/off\\n[tab] = switch to Buttons / List\" 0 0 0 --cancel-button Back --ok-button Install $options 3>&1 1>&2 2>&3)"
  
  if [ $? -eq 1 ] || [ $? -eq 255 ]; then return 0; fi
  
  if [[ "${#downloads}" > 0 ]]; then
    while read -r name; do
      [[ -z "$name" ]] && continue
      # Get download details from config
      local line=$(grep "^$name|" "$DIRECTFILE")
      local display_name=$(echo "$line" | cut -d'|' -f2)
      local description=$(echo "$line" | cut -d'|' -f3)
      local url=$(echo "$line" | cut -d'|' -f4)
      local install_cmd=$(echo "$line" | cut -d'|' -f5)
      install_direct_download "$name" "$display_name" "$description" "$url" "$install_cmd"
    done <<< "$downloads"
  fi
}