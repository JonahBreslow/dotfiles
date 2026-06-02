# dotfiles-sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a drift-detection tool that compares live configs against `~/dev/dotfiles`, sends macOS notifications, and provides an interactive fzf-based resolver.

**Architecture:** Single bash script (`dotfiles-sync`) with two modes: silent `--check` for launchd scheduling, and interactive mode with fzf/bat for manual resolution. A launchd plist schedules daily checks.

**Tech Stack:** Bash, diff, osascript, fzf, bat, launchd

---

## File Structure

| File | Responsibility |
|------|---------------|
| `~/dev/dotfiles/dotfiles-sync` | Main script — drift detection, notification, interactive resolver |
| `~/dev/dotfiles/dotfiles-sync.plist` | launchd agent plist — daily schedule |
| `~/dev/dotfiles/bootstrap.sh` | Modified — adds plist installation + state directory |

---

### Task 1: Drift Detection Core

**Files:**
- Create: `~/dev/dotfiles/dotfiles-sync`

Build the core detection logic that both modes share.

- [ ] **Step 1: Create the script with file mapping arrays**

```bash
#!/usr/bin/env bash

DOTFILES_DIR="$HOME/dev/dotfiles"
STATE_DIR="$HOME/.local/state/dotfiles-sync"

# Home-directory dotfiles: repo-relative path -> same name in $HOME
HOME_FILES=(
    .zshrc
    .bash_profile
    .bashrc
    .exports
    .extra
    .functions
    .gitconfig
    .gitignore
    .inputrc
    .editorconfig
    .vimrc
    .tmux.conf
)

# XDG config directories: repo-relative path -> same in $HOME
XDG_DIRS=(
    .config/nvim
    .config/alacritty
    .config/skhd
    .config/yabai
)
```

- [ ] **Step 2: Add the detect_drift function**

Append to the script:

```bash
detect_drift() {
    local drifted=()

    for file in "${HOME_FILES[@]}"; do
        local repo_path="$DOTFILES_DIR/$file"
        local live_path="$HOME/$file"

        # Skip if either side doesn't exist
        [ -f "$repo_path" ] || continue
        [ -f "$live_path" ] || continue

        # Skip if live file is a symlink into the dotfiles repo
        if [ -L "$live_path" ]; then
            local target
            target="$(readlink "$live_path")"
            [[ "$target" == "$DOTFILES_DIR"* ]] && continue
        fi

        if ! diff -q "$repo_path" "$live_path" > /dev/null 2>&1; then
            drifted+=("$file")
        fi
    done

    for dir in "${XDG_DIRS[@]}"; do
        local repo_path="$DOTFILES_DIR/$dir"
        local live_path="$HOME/$dir"

        [ -d "$repo_path" ] || continue
        [ -d "$live_path" ] || continue

        # Find files that differ within the directory
        while IFS= read -r diffline; do
            local diffed_file
            diffed_file="${diffline#Files }"
            diffed_file="${diffed_file%% and *}"
            diffed_file="${diffed_file#$DOTFILES_DIR/}"
            drifted+=("$diffed_file")
        done < <(diff -rq "$repo_path" "$live_path" 2>/dev/null | grep "^Files ")
    done

    printf '%s\n' "${drifted[@]}"
}
```

- [ ] **Step 3: Make the script executable and test detection manually**

Run:
```bash
chmod +x ~/dev/dotfiles/dotfiles-sync
```

Then temporarily modify a tracked file to create drift and verify detection works:
```bash
echo "# test drift" >> ~/.vimrc
~/dev/dotfiles/dotfiles-sync
```

Expected: `.vimrc` appears in output. Then revert:
```bash
cp ~/dev/dotfiles/.vimrc ~/.vimrc
```

- [ ] **Step 4: Commit**

```bash
cd ~/dev/dotfiles
git add dotfiles-sync
git commit -m "feat(dotfiles-sync): add drift detection core"
```

---

### Task 2: Check Mode (--check)

**Files:**
- Modify: `~/dev/dotfiles/dotfiles-sync`

Add the `--check` flag that runs silently, sends a macOS notification on drift, and logs results.

- [ ] **Step 1: Add check mode logic**

Append to `dotfiles-sync`:

```bash
check_mode() {
    mkdir -p "$STATE_DIR"

    local drifted
    drifted="$(detect_drift)"
    local count
    count="$(echo "$drifted" | grep -c .)"

    # Write log
    {
        echo "--- Check: $(date) ---"
        if [ "$count" -gt 0 ]; then
            echo "Drifted files ($count):"
            echo "$drifted"
        else
            echo "All dotfiles in sync."
        fi
        echo ""
    } >> "$STATE_DIR/last-check.log"

    if [ "$count" -gt 0 ]; then
        osascript -e "display notification \"$count file(s) have diverged from ~/dev/dotfiles\" with title \"Dotfiles Out of Sync\" sound name \"Basso\""
        return 1
    fi

    return 0
}
```

- [ ] **Step 2: Add argument parsing at the bottom of the script**

Append to `dotfiles-sync`:

```bash
case "${1:-}" in
    --check)
        check_mode
        exit $?
        ;;
    "")
        # Interactive mode (Task 3)
        echo "Interactive mode not yet implemented"
        exit 0
        ;;
    *)
        echo "Usage: dotfiles-sync [--check]"
        exit 2
        ;;
esac
```

- [ ] **Step 3: Test check mode**

Create drift then run:
```bash
echo "# test drift" >> ~/.vimrc
~/dev/dotfiles/dotfiles-sync --check
echo $?
cat ~/.local/state/dotfiles-sync/last-check.log
```

Expected: exit code 1, macOS notification appears, log file shows `.vimrc` as drifted. Then revert:
```bash
cp ~/dev/dotfiles/.vimrc ~/.vimrc
```

- [ ] **Step 4: Commit**

```bash
cd ~/dev/dotfiles
git add dotfiles-sync
git commit -m "feat(dotfiles-sync): add --check mode with notification"
```

---

### Task 3: Interactive Mode with fzf

**Files:**
- Modify: `~/dev/dotfiles/dotfiles-sync`

Add the interactive resolver that shows drifted files in fzf with bat preview and per-file action prompts.

- [ ] **Step 1: Add the interactive mode function**

Replace the `""` case placeholder with a call to `interactive_mode`, and add the function before the `case` statement:

```bash
interactive_mode() {
    local drifted
    drifted="$(detect_drift)"

    if [ -z "$drifted" ]; then
        echo "All dotfiles in sync."
        exit 0
    fi

    local count
    count="$(echo "$drifted" | wc -l | tr -d ' ')"
    echo "$count file(s) out of sync."
    echo ""

    # Check for fzf/bat availability
    local use_fzf=true
    if ! command -v fzf &> /dev/null; then
        echo "fzf not found — falling back to plain mode."
        use_fzf=false
    fi

    local selected_files=()

    if [ "$use_fzf" = true ]; then
        local preview_cmd
        if command -v bat &> /dev/null; then
            preview_cmd="diff -u '$DOTFILES_DIR/{}' '$HOME/{}' | bat --style=plain --language=diff --color=always"
        else
            preview_cmd="diff -u --color=always '$DOTFILES_DIR/{}' '$HOME/{}'"
        fi

        while IFS= read -r file; do
            [ -n "$file" ] && selected_files+=("$file")
        done < <(echo "$drifted" | fzf --multi \
            --header="TAB to select files, ENTER to resolve" \
            --preview="$preview_cmd" \
            --preview-window=right:60%)
    else
        # Plain fallback: list all drifted files
        echo "Drifted files:"
        echo "$drifted"
        echo ""
        mapfile -t selected_files <<< "$drifted"
    fi

    if [ ${#selected_files[@]} -eq 0 ]; then
        echo "No files selected."
        exit 0
    fi

    resolve_files "${selected_files[@]}"
}
```

- [ ] **Step 2: Add the resolve_files function**

Add before `interactive_mode`:

```bash
resolve_files() {
    local files=("$@")
    local committed_to_repo=()

    for file in "${files[@]}"; do
        echo ""
        echo "=== $file ==="
        echo "  [r] Copy live → repo"
        echo "  [l] Restore from repo → live"
        echo "  [d] Show full diff"
        echo "  [s] Skip"
        echo ""

        while true; do
            read -p "Action for $file: " -n 1 action
            echo ""

            case "$action" in
                r)
                    cp "$HOME/$file" "$DOTFILES_DIR/$file"
                    echo "  Copied live → repo"
                    committed_to_repo+=("$file")
                    break
                    ;;
                l)
                    cp "$DOTFILES_DIR/$file" "$HOME/$file"
                    echo "  Restored from repo → live"
                    break
                    ;;
                d)
                    ${PAGER:-less} <(diff -u "$DOTFILES_DIR/$file" "$HOME/$file")
                    ;;
                s)
                    echo "  Skipped"
                    break
                    ;;
                *)
                    echo "  Invalid option. Use r/l/d/s."
                    ;;
            esac
        done
    done

    if [ ${#committed_to_repo[@]} -gt 0 ]; then
        echo ""
        read -p "Commit ${#committed_to_repo[@]} file(s) to dotfiles repo? (y/n) " -n 1
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "$DOTFILES_DIR"
            git add "${committed_to_repo[@]}"
            local filenames
            filenames="$(printf '%s ' "${committed_to_repo[@]}")"
            git commit -m "sync: update ${filenames% }"
            echo "Committed."
        else
            echo "Changes copied but not committed."
        fi
    fi
}
```

- [ ] **Step 3: Update the case statement**

Replace the interactive mode placeholder:

```bash
case "${1:-}" in
    --check)
        check_mode
        exit $?
        ;;
    "")
        interactive_mode
        ;;
    *)
        echo "Usage: dotfiles-sync [--check]"
        exit 2
        ;;
esac
```

- [ ] **Step 4: Test interactive mode**

Create drift and run interactively:
```bash
echo "# test drift" >> ~/.vimrc
~/dev/dotfiles/dotfiles-sync
```

Expected: fzf opens with `.vimrc` listed, preview shows the diff. Select it, press Enter, then press `l` to restore from repo.

- [ ] **Step 5: Commit**

```bash
cd ~/dev/dotfiles
git add dotfiles-sync
git commit -m "feat(dotfiles-sync): add interactive fzf resolver"
```

---

### Task 4: launchd Plist

**Files:**
- Create: `~/dev/dotfiles/dotfiles-sync.plist`

- [ ] **Step 1: Create the plist file**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.jonah.dotfiles-sync</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/jonah/dev/dotfiles/dotfiles-sync</string>
        <string>--check</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>10</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/Users/jonah/.local/state/dotfiles-sync/launchd.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/jonah/.local/state/dotfiles-sync/launchd.log</string>
</dict>
</plist>
```

- [ ] **Step 2: Validate the plist**

Run:
```bash
plutil -lint ~/dev/dotfiles/dotfiles-sync.plist
```

Expected: `dotfiles-sync.plist: OK`

- [ ] **Step 3: Commit**

```bash
cd ~/dev/dotfiles
git add dotfiles-sync.plist
git commit -m "feat(dotfiles-sync): add launchd plist for daily checks"
```

---

### Task 5: bootstrap.sh Integration

**Files:**
- Modify: `~/dev/dotfiles/bootstrap.sh`

Add plist installation at the end of `bootstrap.sh`, after the oh-my-zsh/PL10K section.

- [ ] **Step 1: Add dotfiles-sync installation to bootstrap.sh**

Append to the end of `bootstrap.sh`:

```bash
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
```

- [ ] **Step 2: Add dotfiles-sync to bootstrap.sh rsync exclusions**

Add to the rsync exclude list in the `doIt` function:

```bash
--exclude "dotfiles-sync" \
--exclude "dotfiles-sync.plist" \
--exclude "docs/" \
```

- [ ] **Step 3: Test the bootstrap addition**

Run:
```bash
cd ~/dev/dotfiles && bash bootstrap.sh --force --skip-extensions
launchctl list | grep dotfiles-sync
```

Expected: the agent appears in launchctl list output.

- [ ] **Step 4: Commit**

```bash
cd ~/dev/dotfiles
git add bootstrap.sh
git commit -m "feat(bootstrap): install dotfiles-sync launchd agent"
```

---

### Task 6: Smoke Test End-to-End

**Files:** None (verification only)

- [ ] **Step 1: Verify check mode sends notification**

```bash
echo "# e2e test" >> ~/.vimrc
~/dev/dotfiles/dotfiles-sync --check
```

Expected: macOS notification "Dotfiles Out of Sync — 1 file(s) have diverged..."

- [ ] **Step 2: Verify interactive mode resolves drift**

```bash
~/dev/dotfiles/dotfiles-sync
```

Expected: fzf opens, `.vimrc` listed, select it, press `l` to restore from repo.

- [ ] **Step 3: Verify clean state**

```bash
~/dev/dotfiles/dotfiles-sync --check
echo $?
```

Expected: exit code 0, no notification.

- [ ] **Step 4: Verify launchd is loaded**

```bash
launchctl list | grep dotfiles-sync
```

Expected: shows `com.jonah.dotfiles-sync` with PID `-` (not currently running) and status `0`.
