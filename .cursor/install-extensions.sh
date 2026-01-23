#!/usr/bin/env bash

# Install Cursor extensions from extensions.txt
# This script will install all extensions listed in the extensions.txt file

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTENSIONS_FILE="$SCRIPT_DIR/extensions.txt"

if [ ! -f "$EXTENSIONS_FILE" ]; then
    echo "Error: extensions.txt not found at $EXTENSIONS_FILE"
    exit 1
fi

echo "Installing Cursor extensions..."
echo "This may take a few minutes..."
echo ""

# Count total extensions
total=$(wc -l < "$EXTENSIONS_FILE" | tr -d ' ')
current=0

while IFS= read -r extension || [ -n "$extension" ]; do
    # Skip empty lines and comments
    [[ -z "$extension" || "$extension" =~ ^# ]] && continue
    
    current=$((current + 1))
    echo "[$current/$total] Installing $extension..."
    cursor --install-extension "$extension" --force 2>&1 | grep -v "is already installed"
done < "$EXTENSIONS_FILE"

echo ""
echo "✅ All extensions installed successfully!"
echo "You may need to restart Cursor for all extensions to be fully loaded."
