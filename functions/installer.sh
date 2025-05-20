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

rvm_install() {
  echo "Installing RVM (Ruby Version Manager)..."
  \curl -sSL https://get.rvm.io | bash -s stable --ruby
  source ~/.rvm/scripts/rvm
  echo "RVM installation finished. Please reload your shell or source ~/.rvm/scripts/rvm."
}

zsh_install() {
  # Symlink macOStraps .zshrc to your $HOME
  ln -sfn $BASEDIR/dotfiles/.zshrc ~/.zshrc # Added -f to overwrite if exists, -n to not follow symlinks

  # Install zsh
  brew install zsh
  echo

  # Install zplug
  echo "Installing zplug..."
  if [ -d "$HOME/.zplug" ]; then
    echo "zplug already installed at ~/.zplug. Skipping clone."
  else
    export ZPLUG_HOME=~/.zplug
    git clone https://github.com/zplug/zplug $ZPLUG_HOME
    if [ $? -eq 0 ]; then
      echo "zplug installed successfully."
    else
      echo "zplug installation failed."
      # Optionally, exit or handle error
    fi
  fi
  # Ensure ZPLUG_HOME is set for the current session and .zshrc
  export ZPLUG_HOME=~/.zplug 
  echo 'export ZPLUG_HOME=~/.zplug' >> ~/.zshrc # Add to .zshrc for future sessions

  echo
  echo "+––––––––––––––––+"
  echo "| PLEASE NOTICE! |"
  echo "+––––––––––––––––+"
  echo
  echo "We are about to add brews zsh to your /etc/shells and activate zsh for the"
  echo "first time."
  echo "For this we need superuser privileges."
  echo

  # Add brew zsh to /etc/shells and switch default-shell
  BREW_ZSH_PATH=$(brew --prefix)/bin/zsh
  if ! grep -Fxq "$BREW_ZSH_PATH" /etc/shells; then
    echo "Adding $BREW_ZSH_PATH to /etc/shells"
    echo "$BREW_ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
  fi

  if [ "$SHELL" != "$BREW_ZSH_PATH" ]; then
    chsh -s "$BREW_ZSH_PATH"
    echo "Default shell changed to $BREW_ZSH_PATH. Please log out and log back in for changes to take effect."
  fi

  # Install fzf fuzzy completion
  if ! brew list fzf &>/dev/null; then
    brew install fzf && $(brew --prefix)/opt/fzf/install --all
  else
    echo "fzf already installed. Skipping fzf installation."
  fi
  # The exec zsh line might be problematic if the script is sourced or run in a subshell
  # It's generally better to inform the user to restart their shell or source .zshrc
  echo "Zsh setup complete. Please restart your terminal or source your .zshrc."
}
