#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

git pull origin main;

function doIt() {
	rsync --exclude ".git/" \
		--exclude ".DS_Store" \
		--exclude ".osx" \
		--exclude "bootstrap.sh" \
		--exclude "brew.sh" \
		--exclude "init/" \
		--exclude ".cursor/" \
		--exclude "README.md" \
		--exclude "LICENSE-MIT.txt" \
		--exclude "dotfiles-sync" \
		--exclude "dotfiles-sync.plist" \
		--exclude "docs/" \
		-avh --no-perms . ~;
	source ~/.zshrc;
}

if [ "$1" = "--force" -o "$1" = "-f" ]; then
	doIt;
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
	fi;
fi;
unset doIt;

# Cursor configuration
function setupCursor() {
	CURSOR_USER_DIR="$HOME/Library/Application Support/Cursor/User"
	DOTFILES_CURSOR_DIR="$(cd "$(dirname "${BASH_SOURCE}")"; pwd)/.cursor"
	
	if [ -d "$DOTFILES_CURSOR_DIR" ]; then
		echo "Setting up Cursor configuration..."
		mkdir -p "$CURSOR_USER_DIR"
		
		# Backup existing files if they exist and aren't symlinks
		if [ -f "$CURSOR_USER_DIR/settings.json" ] && [ ! -L "$CURSOR_USER_DIR/settings.json" ]; then
			mv "$CURSOR_USER_DIR/settings.json" "$CURSOR_USER_DIR/settings.json.backup"
			echo "Backed up existing settings.json to settings.json.backup"
		fi
		
		if [ -f "$CURSOR_USER_DIR/keybindings.json" ] && [ ! -L "$CURSOR_USER_DIR/keybindings.json" ]; then
			mv "$CURSOR_USER_DIR/keybindings.json" "$CURSOR_USER_DIR/keybindings.json.backup"
			echo "Backed up existing keybindings.json to keybindings.json.backup"
		fi
		
		# Create symlinks
		ln -sf "$DOTFILES_CURSOR_DIR/settings.json" "$CURSOR_USER_DIR/settings.json"
		ln -sf "$DOTFILES_CURSOR_DIR/keybindings.json" "$CURSOR_USER_DIR/keybindings.json"
		
		echo "Cursor configuration linked successfully!"
	fi
}

setupCursor;
unset setupCursor;

# Install Cursor extensions
function installCursorExtensions() {
	DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE}")"; pwd)"
	EXTENSIONS_SCRIPT="$DOTFILES_DIR/.cursor/install-extensions.sh"
	
	if [ -f "$EXTENSIONS_SCRIPT" ] && command -v cursor &> /dev/null; then
		read -p "Would you like to install Cursor extensions? (y/n) " -n 1;
		echo "";
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			bash "$EXTENSIONS_SCRIPT"
		else
			echo "Skipping Cursor extensions installation."
			echo "You can install them later by running: $EXTENSIONS_SCRIPT"
		fi
	fi
}

if [ "$1" != "--skip-extensions" ]; then
	installCursorExtensions;
	unset installCursorExtensions;
fi

# oh my zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended > /dev/null 2>&1
fi

# PL10K
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ] || \
	git clone https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" > /dev/null 2>&1
[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] || \
	git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" > /dev/null 2>&1
[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] || \
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" > /dev/null 2>&1

# dotfiles-sync: drift detection agent
function setupDotfilesSync() {
	local STATE_DIR="$HOME/.local/state/dotfiles-sync"
	local PLIST_SRC="$(cd "$(dirname "${BASH_SOURCE}")"; pwd)/dotfiles-sync.plist"
	local PLIST_DST="$HOME/Library/LaunchAgents/com.jonah.dotfiles-sync.plist"

	mkdir -p "$STATE_DIR"

	if [ -f "$PLIST_SRC" ]; then
		# Unload existing if present (ignore errors if not loaded)
		launchctl unload "$PLIST_DST" 2>/dev/null

		# Symlink the plist
		ln -sf "$PLIST_SRC" "$PLIST_DST"

		# Load the agent
		launchctl load "$PLIST_DST"
		echo "dotfiles-sync launchd agent installed and loaded."
	fi
}

setupDotfilesSync;
unset setupDotfilesSync;
