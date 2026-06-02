# dotfiles-sync Design Spec

## Purpose

Detect when live application configs on the machine have diverged from their version-controlled counterparts in `~/dev/dotfiles`, notify via macOS notification, and provide an interactive TUI to resolve differences per-file.

## File Mapping

The script tracks two categories of files:

### Home-directory dotfiles (1:1 by filename)

Repo path `~/dev/dotfiles/<file>` maps to `~/<file>`. Includes:

- `.zshrc`
- `.bash_profile`
- `.bashrc`
- `.exports`
- `.extra`
- `.functions`
- `.gitconfig`
- `.gitignore`
- `.inputrc`
- `.editorconfig`
- `.vimrc`
- `.tmux.conf`

### XDG configs (recursive directory comparison)

Repo path `~/dev/dotfiles/.config/<dir>/` maps to `~/.config/<dir>/`. Includes:

- `.config/nvim/`
- `.config/alacritty/`
- `.config/skhd/`
- `.config/yabai/`

### Excluded (already symlinked)

- `.cursor/` — symlinked by `bootstrap.sh`, always in sync by definition

### Detection logic

- For each mapped file/directory, run `diff -q` (files) or `diff -rq` (directories)
- Skip files that don't exist on either side (new files in the repo that haven't been deployed yet)
- Skip symlinks pointing into the dotfiles repo (already in sync)

## Modes

### Check mode: `dotfiles-sync --check`

Called by launchd on a daily schedule.

1. Iterate all mapped paths, compare live vs repo
2. Collect list of diverged files
3. If any divergence:
   - Send macOS notification via `osascript -e 'display notification'`
   - Notification title: "Dotfiles Out of Sync"
   - Notification body: e.g., "3 files have diverged from ~/dev/dotfiles"
   - Notification has no action button (standard macOS limitation for osascript)
4. Exit code: 0 = no drift, 1 = drift detected
5. Write drift results to `~/.local/state/dotfiles-sync/last-check.log` for reference

### Interactive mode: `dotfiles-sync`

Run manually (likely after seeing the notification).

1. Run the same drift detection as check mode
2. If no drift, print "All dotfiles in sync" and exit
3. If drift detected, launch `fzf` with:
   - List of drifted file paths (relative to repo)
   - Preview pane showing the diff via `bat --diff` or `diff --color`
   - Multi-select enabled (tab to select multiple files)
4. For each selected file, prompt with options:
   - `r` — copy live version to repo (overwrite repo file)
   - `l` — restore from repo (overwrite live file)
   - `s` — skip this file
   - `d` — show full diff in `$PAGER` before deciding
5. After processing all selections, if any files were copied to repo:
   - Ask: "Commit changes to dotfiles repo? (y/n)"
   - If yes: `git add` the changed files, commit with message "sync: update <filenames>"
   - Do NOT auto-push (user pushes manually)

## Scheduling

### launchd plist: `com.jonah.dotfiles-sync.plist`

- Location in repo: `~/dev/dotfiles/dotfiles-sync.plist`
- Installed to: `~/Library/LaunchAgents/com.jonah.dotfiles-sync.plist` (symlink)
- Schedule: daily at 10:00 AM (runs on wake if missed)
- Invokes: `~/dev/dotfiles/dotfiles-sync --check`
- Standard out/err: `~/.local/state/dotfiles-sync/launchd.log`

### Installation

`bootstrap.sh` will:
1. Create `~/.local/state/dotfiles-sync/` directory
2. Symlink the plist to `~/Library/LaunchAgents/`
3. Run `launchctl load` on the plist (if not already loaded)

## File structure (new files in repo)

```
~/dev/dotfiles/
├── dotfiles-sync                # main script (executable)
├── dotfiles-sync.plist          # launchd plist
├── bootstrap.sh                 # (modified: adds plist install + state dir)
```

## Dependencies

- `fzf` — file picker in interactive mode
- `bat` — syntax-highlighted diff preview
- Both required only for interactive mode; check mode has zero external dependencies
- If `fzf`/`bat` not found in interactive mode, fall back to plain `diff` output with manual prompts

## Error handling

- If a mapped live file doesn't exist: skip it silently (not yet deployed)
- If a mapped repo file doesn't exist: skip it (file was removed from repo)
- If `fzf`/`bat` not installed: degrade gracefully to plain terminal output
- Launchd log captures any stderr from check mode

## Future considerations (not in scope)

- Auto-push after commit
- Watch mode (fsevents-based real-time detection)
- Notification action button (requires a proper macOS app bundle)
