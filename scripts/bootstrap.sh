#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

REPO_DIR="$(pwd)"
BOOTSTRAP_STATE_DIR="$HOME/.nix-macos-bootstrap"
RESUME_MARKER="$BOOTSTRAP_STATE_DIR/resume-after-reboot"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_PLIST="$LAUNCH_AGENTS_DIR/com.edgravill.nix-macos-bootstrap.plist"
BOOTSTRAP_LOG="$BOOTSTRAP_STATE_DIR/bootstrap.log"

mkdir -p "$BOOTSTRAP_STATE_DIR"

request_sudo() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Requesting administrator privileges for the bootstrap..."
    sudo -v

    while true; do
      sudo -n true
      sleep 60
      kill -0 "$$" 2>/dev/null || exit
    done 2>/dev/null &

    SUDO_KEEPALIVE_PID="$!"

    cleanup_sudo_keepalive() {
      kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    }

    trap cleanup_sudo_keepalive EXIT
  fi
}

load_nix_profile() {
  if [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
    . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
  elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
}

prepare_etc_for_nix_darwin() {
  for file in /etc/bashrc /etc/zshrc; do
    if [ -e "$file" ] && [ ! -e "$file.before-nix-darwin" ]; then
      echo "Moving $file to $file.before-nix-darwin so nix-darwin can manage it..."
      sudo mv "$file" "$file.before-nix-darwin"
    fi
  done
}

install_resume_launch_agent() {
  mkdir -p "$LAUNCH_AGENTS_DIR"

  cat > "$LAUNCH_AGENT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>com.edgravill.nix-macos-bootstrap</string>

    <key>RunAtLoad</key>
    <true/>

    <key>ProgramArguments</key>
    <array>
      <string>/usr/bin/osascript</string>
      <string>-e</string>
      <string>tell application "Terminal" to do script "cd '$REPO_DIR' &amp;&amp; ./scripts/bootstrap.sh"</string>
    </array>

    <key>StandardOutPath</key>
    <string>$BOOTSTRAP_STATE_DIR/launch-agent.out.log</string>

    <key>StandardErrorPath</key>
    <string>$BOOTSTRAP_STATE_DIR/launch-agent.err.log</string>
  </dict>
</plist>
EOF

  launchctl unload "$LAUNCH_AGENT_PLIST" >/dev/null 2>&1 || true
  launchctl load "$LAUNCH_AGENT_PLIST"
}

remove_resume_launch_agent() {
  if [ -f "$LAUNCH_AGENT_PLIST" ]; then
    launchctl unload "$LAUNCH_AGENT_PLIST" >/dev/null 2>&1 || true
    rm -f "$LAUNCH_AGENT_PLIST"
  fi

  rm -f "$RESUME_MARKER"
}

detect_reboot_required_from_log() {
  local log_file="$1"

  grep -Eiq \
    'filevault|restart|reboot|reboot.*required|restart.*required|volume.*encrypt|encrypted volume' \
    "$log_file"
}

install_nix_non_interactive() {
  echo "Installing Nix non-interactively..."

  local installer="/tmp/nix-install.sh"
  local install_log="$BOOTSTRAP_STATE_DIR/nix-install.log"

  curl -L https://nixos.org/nix/install -o "$installer"

  set +e
  sh "$installer" --daemon --yes 2>&1 | tee "$install_log"
  local status="${PIPESTATUS[0]}"
  set -e

  if [ "$status" -ne 0 ]; then
    if detect_reboot_required_from_log "$install_log"; then
      echo
      echo "Nix installer indicates a reboot is required, likely due to FileVault/APFS volume setup."
      echo "Preparing automatic bootstrap resume after login..."

      touch "$RESUME_MARKER"
      install_resume_launch_agent

      echo "Rebooting now. After you log back in, Terminal should reopen and continue bootstrap."
      sudo shutdown -r now
      exit 0
    fi

    echo "Nix installer failed. See log:"
    echo "  $install_log"
    exit "$status"
  fi

  load_nix_profile
}

finish_todo() {
  mkdir -p "$HOME/Desktop"
  cp ./todo.md "$HOME/Desktop/nix-restore-todo.md"

  if command -v code >/dev/null 2>&1; then
    code "$HOME/Desktop/nix-restore-todo.md" || true
  else
    open -a "Visual Studio Code" "$HOME/Desktop/nix-restore-todo.md" 2>/dev/null || true
  fi
}

main() {
  request_sudo

  if [ -f "$RESUME_MARKER" ]; then
    echo "Resuming bootstrap after reboot..."
  fi

  if ! command -v nix >/dev/null 2>&1; then
    install_nix_non_interactive
  else
    load_nix_profile
  fi

  if ! command -v nix >/dev/null 2>&1; then
    echo
    echo "Nix was installed, but it is still not available in this shell."
    echo "Open a new terminal and run:"
    echo
    echo "  cd '$REPO_DIR' && ./scripts/bootstrap.sh"
    echo
    exit 1
  fi

  prepare_etc_for_nix_darwin

  ./scripts/apply.sh

  ./scripts/setup-dock.sh || true

  if [ -d "./secrets" ]; then
    ./scripts/restore-ssh.sh || true
    ./scripts/restore-gpg.sh || true
    ./scripts/restore-home-files.sh || true
    ./scripts/restore-iterm2.sh || true
    ./scripts/restore-widgets.sh || true
    ./scripts/restore-wallpapers.sh || true
    ./scripts/restore-repos.sh || true
  else
    echo "No ./secrets folder found. Skipping secrets restore."
  fi

  ./scripts/apply.sh
  ./scripts/setup-dock.sh || true

  finish_todo
  remove_resume_launch_agent

  echo
  echo "Bootstrap complete."
  echo "Review: $HOME/Desktop/nix-restore-todo.md"
}

main "$@" 2>&1 | tee -a "$BOOTSTRAP_LOG"
