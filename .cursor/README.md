# Cursor Configuration

This directory contains Cursor IDE configuration files that will be synced across machines.

## Files

- `settings.json` - Editor settings, vim keybindings, language-specific formatters, and UI preferences
- `keybindings.json` - Custom keyboard shortcuts for file explorer, terminal navigation, and editor management
- `extensions.txt` - List of all installed Cursor extensions
- `install-extensions.sh` - Script to automatically install all extensions

## Setup

When you run `bootstrap.sh`, these files will be automatically symlinked to:
```
~/Library/Application Support/Cursor/User/
```

Any changes you make in Cursor will be reflected in these files, making it easy to keep your configuration in sync across machines.

## Installing Extensions

The `bootstrap.sh` script will prompt you to install extensions. You can also install them manually:

```bash
cd ~/dotfiles/.cursor
./install-extensions.sh
```

## Updating Extensions List

If you install new extensions on your current machine and want to update the list:

```bash
cursor --list-extensions > ~/dotfiles/.cursor/extensions.txt
cd ~/dotfiles
git add .cursor/extensions.txt
git commit -m "Update Cursor extensions"
git push
```
