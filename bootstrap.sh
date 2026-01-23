#!/usr/bin/env bash

cd "$(dirname "${BASH_SOURCE}")";

git pull origin main;

function doIt() {
	rsync --exclude ".git/" \
		--exclude ".DS_Store" \
		--exclude ".osx" \
		--exclude "bootstrap.sh" \
		--exclude "README.md" \
		--exclude "LICENSE-MIT.txt" \
		-avh --no-perms . ~;
	source ~/.bash_profile;
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
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" > /dev/null 2>&1

# PL10K
git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k > /dev/null 2>&1
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions > /dev/null 2>&1
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting > /dev/null 2>&1
