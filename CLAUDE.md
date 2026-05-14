# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Bash-only collection of installers for Ubuntu environments — no compiled code, no tests, no package manifest. Three independent modules orchestrated by an interactive menu:

- `ubuntu-setup/` — Ubuntu 22.04+ desktop dev environment (GNOME)
- `server-setup/` — Ubuntu 22.04+ headless server (Docker, Traefik, dnsmasq, static IP)
- `hardware-check.sh` — post-OS-install hardware integrity verification (RAM, SSD, CPU stress, temperature)

All user-facing strings are in **Brazilian Portuguese**. Match that when adding prompts or log messages.

## Running things

```bash
# Local execution (after cloning)
bash install.sh                       # interactive menu
sudo bash ubuntu-setup/install.sh     # desktop module directly
sudo bash server-setup/install.sh     # server module directly
sudo bash hardware-check.sh           # hardware module (runs sudo internally where needed)

# Remote bootstrap (what end users actually invoke)
bash -c "$(wget -qO- https://raw.githubusercontent.com/anisotton/utils/main/boot.sh)"
bash -c "$(wget -qO- https://raw.githubusercontent.com/anisotton/utils/main/boot-server.sh)"

# Install from a non-main branch (boot scripts honor this)
UTILS_REF=develop bash -c "$(wget -qO- https://raw.githubusercontent.com/anisotton/utils/main/boot.sh)"
```

There are no lint, build, or test commands. Verify changes by running the affected installer end-to-end on a disposable VM.

## Architecture

### Orchestrator + sourced installers

Each module's `install.sh` is the orchestrator. It `source`s individual installer scripts under `install/<category>/`:

- **Order-sensitive categories** prefix files with `NN-` (e.g. `core/01-prerequisites.sh`, `network/01-static-ip.sh`, `runtime/01-node.sh`). Glob expansion runs them in alphabetical order — preserve the prefix and pick a new number when adding.
- **Order-independent categories** (`apps/`, `desktop/`) have no prefix.
- **Optional categories** (`ai-tools/`) are not auto-globbed; the orchestrator sources specific files based on interactive selection. New AI tools must be wired into the menu in the relevant `install.sh`.

Because scripts are sourced (not executed), they share the orchestrator's variables and helpers. `set -e` in the orchestrator means a failure anywhere aborts the whole run.

### Shared helpers

`ubuntu-setup/lib/helpers.sh` is the single source of truth for shared utilities. `server-setup/lib/helpers.sh` is a thin shim that sources it after computing `UBUNTU_SETUP_PATH`. Use these instead of reimplementing:

- `log_info` / `log_warning` / `log_error` — colored stdout, never plain `echo` for status
- `ensure_packages pkg1 pkg2 …` — apt-installs only missing ones (preferred over raw `apt-get install`)
- `apt_install_packages …` — unconditional install
- `run_as_user "cmd"` — runs `cmd` as `$SUDO_USER` when invoked via sudo, transparently; use this for **anything that touches `$HOME`** (dotfiles, user clones, user-scoped installers like nvm/oh-my-zsh) to avoid root-owned files
- `setup_user_detection` — runs on source; populates `REAL_USER`, `REAL_HOME`, `COMPOSER_BIN`. Don't read `$HOME` directly in installers — use `$REAL_HOME`
- `install_agent_skills "/target/dir"` — symlinks `skills/` into the target. Used by AI-tool installers so new skill folders are picked up without re-running setup

### Dual-mode root/non-root

Installers must work both as `sudo bash install.sh` (EUID 0, with `$SUDO_USER`) and as a regular user (helpers will `sudo` as needed). The pattern throughout is:

```bash
if [ "$EUID" -eq 0 ]; then
    some_command
else
    sudo some_command
fi
```

When writing a new installer, follow this pattern or use helpers that already encapsulate it.

### Idempotency is mandatory

Every installer is expected to be re-runnable. Before installing or configuring, check current state:

- Binaries: `command -v foo &> /dev/null`
- apt packages: `dpkg -s pkg` (or just use `ensure_packages`)
- Directories: `[ ! -d "$REAL_HOME/.oh-my-zsh" ]`
- Services: `docker ps --format '{{.Names}}' | grep -q '^traefik$'`
- Config files: grep for a sentinel line before appending

Server installers may `return 0 2>/dev/null || exit 0` to short-circuit when already configured (necessary because scripts can be either sourced or executed).

### Server orchestrator passes state via env

`server-setup/install.sh` prompts for `SERVER_IP` and `SERVER_NAME` upfront, exports them, then sources each `install/*/` script. Individual scripts (e.g. `network/02-dnsmasq.sh`, the final summary in `install.sh`) read those exports. Don't re-prompt inside installers — fall back to a sane default if the env var is missing, but assume the orchestrator set it.

### Templated configs

`ubuntu-setup/configs/aliases.zsh` uses `__PROJECTS_PATH__` as a placeholder, substituted via `sed` at install time in `core/02-zsh.sh` after asking the user where their projects live. Use the same convention if you add other user-path-dependent configs.

### Skills

`skills/` contains agent skills (each `<name>/SKILL.md`) that get **symlinked** (not copied) into `~/.claude/skills` and `~/.copilot/skills` by the AI-tool installers via `install_agent_skills`. Adding a new skill folder is enough — no installer changes needed. The symlink approach means edits in the repo are immediately reflected in installed AI tools.

## Files to know about

- **`ubuntu-dev-setup.sh`** (root, 739 lines) — legacy monolithic version of `ubuntu-setup/`. Not referenced by `boot.sh`, `install.sh`, or anything else in the modular tree. New work belongs in `ubuntu-setup/install/`, not here.
- **`init_prompt.md`** — original spec the modular Ubuntu installers were derived from. Useful as historical context; not a source of truth for current behavior.
- **`boot.sh` / `boot-server.sh`** — remote bootstraps. They `rm -rf "$HOME/.local/share/utils"` before cloning, so any local changes there are discarded each run. Don't edit anything under `~/.local/share/utils` expecting it to survive.
