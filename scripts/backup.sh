#!/usr/bin/env bash
set -Eeuo pipefail

IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"

CODE_DIR="${CODE_DIR:-$HOME/code}"
DOWNLOADS_DIR="${DOWNLOADS_DIR:-$HOME/Downloads}"
SECRETS_DIR="${SECRETS_DIR:-$REPO_ROOT/secrets}"

REPORTS_DIR="$SECRETS_DIR/reports"
REPOS_DIR="$SECRETS_DIR/repos"
REPO_STRUCTURE_DIR="$REPOS_DIR/structure"
SSH_BACKUP_DIR="$SECRETS_DIR/ssh"
GPG_BACKUP_DIR="$SECRETS_DIR/gpg"
HOME_FILES_DIR="$SECRETS_DIR/home-files"

mkdir -p "$REPORTS_DIR" "$REPOS_DIR" "$REPO_STRUCTURE_DIR" "$SSH_BACKUP_DIR" "$GPG_BACKUP_DIR" "$HOME_FILES_DIR"

timestamp() { date +"%Y-%m-%d %H:%M:%S"; }
log() { printf '[%s] %s\n' "$(timestamp)" "$*"; }
warn() { printf '\nWARNING: %s\n\n' "$*" >&2; }
fail() { printf '\nERROR: %s\n\n' "$*" >&2; exit 1; }

confirm() {
  local prompt="${1:-Continue?}"
  printf '%s [y/N]: ' "$prompt"
  read -r answer
  case "$answer" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

is_downloads_effectively_empty() {
  local dir="$1"
  [ -d "$dir" ] || return 0

  # Finder/system cruft should not count as user files.
  [ -z "$(
    find "$dir" -mindepth 1 -maxdepth 1       ! -name ".DS_Store"       ! -name ".localized"       ! -name ".com.apple.timemachine.supported"       ! -name ".TemporaryItems"       ! -name ".Trashes"       -print -quit 2>/dev/null
  )" ]
}

remote_host_from_url() {
  local url="$1"
  if [[ "$url" =~ ^[^/@:]+@([^/:]+): ]]; then printf '%s\n' "${BASH_REMATCH[1]}"; return 0; fi
  if [[ "$url" =~ ^ssh://([^/@]+@)?([^/:]+)[:/].* ]]; then printf '%s\n' "${BASH_REMATCH[2]}"; return 0; fi
  if [[ "$url" =~ ^https?://([^/]+)/.* ]]; then printf '%s\n' "${BASH_REMATCH[1]}"; return 0; fi
  return 1
}

remote_scheme_from_url() {
  local url="$1"
  if [[ "$url" =~ ^[^/@:]+@([^/:]+): ]]; then printf 'ssh\n'; return 0; fi
  if [[ "$url" =~ ^ssh:// ]]; then printf 'ssh\n'; return 0; fi
  if [[ "$url" =~ ^https?:// ]]; then printf 'https\n'; return 0; fi
  printf 'unknown\n'
}

load_ssh_host_aliases() {
  local config="$HOME/.ssh/config"
  local output="$REPORTS_DIR/ssh-hosts-detected.txt"
  : > "$output"

  printf '%s\n' "github.com" "hf.co" "localhost" "127.0.0.1" >> "$output"

  if [ -f "$config" ]; then
    awk '
      BEGIN { IGNORECASE = 1 }
      /^[[:space:]]*Host[[:space:]]+/ {
        for (i = 2; i <= NF; i++) {
          if ($i !~ /[*?]/) print $i
        }
      }
    ' "$config" >> "$output"
  fi

  sort -u "$output" -o "$output"
}

ssh_host_known() {
  local host="$1"
  grep -Fxq "$host" "$REPORTS_DIR/ssh-hosts-detected.txt"
}

find_git_repos() {
  local root="$1"
  local output="$2"
  : > "$output"

  [ -d "$root" ] || return 0

  # Robust recursive lookup for macOS Bash 3.2.
  # Stop descending as soon as a directory has .git.
  local queue_file
  local next_queue_file
  local dir

  queue_file="$(mktemp)"
  next_queue_file="$(mktemp)"
  printf '%s\n' "$root" > "$queue_file"

  while [ -s "$queue_file" ]; do
    : > "$next_queue_file"

    while IFS= read -r dir; do
      [ -d "$dir" ] || continue

      if [ -e "$dir/.git" ]; then
        printf '%s\n' "$dir" >> "$output"
        continue
      fi

      find "$dir" -mindepth 1 -maxdepth 1 -type d         ! -name ".git"         ! -name "node_modules"         ! -name ".next"         ! -name "dist"         ! -name "build"         ! -name ".direnv"         -print 2>/dev/null >> "$next_queue_file"
    done < "$queue_file"

    mv "$next_queue_file" "$queue_file"
    next_queue_file="$(mktemp)"
  done

  rm -f "$queue_file" "$next_queue_file"
  sort -u "$output" -o "$output"
}

relative_to_code_dir() {
  local path="$1"
  printf '%s\n' "${path#$CODE_DIR/}"
}

repo_primary_remote() {
  local repo="$1"
  local remote_url=""
  remote_url="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
  if [ -z "$remote_url" ]; then
    remote_url="$(git -C "$repo" remote -v 2>/dev/null | awk 'NR == 1 { print $2 }')"
  fi
  printf '%s\n' "$remote_url"
}

repo_is_dirty() {
  local repo="$1"
  [ -n "$(git -C "$repo" status --porcelain=v1 2>/dev/null)" ]
}

repo_current_branch() {
  local repo="$1"
  git -C "$repo" branch --show-current 2>/dev/null || true
}

make_repo_reports() {
  local repo_list_file="$REPORTS_DIR/git-repo-paths.absolute.txt"
  local repos_tsv="$REPOS_DIR/repos.tsv"
  local repos_txt="$REPOS_DIR/repos.txt"
  local tree_txt="$REPOS_DIR/tree.txt"
  local restore_plan="$REPOS_DIR/restore-plan.tsv"
  local dirty_file="$REPORTS_DIR/repos-with-uncommitted-changes.txt"
  local unknown_hosts_file="$REPORTS_DIR/repos-with-unknown-ssh-hosts.txt"
  local no_remote_file="$REPORTS_DIR/repos-without-remotes.txt"

  : > "$repos_tsv"
  : > "$repos_txt"
  : > "$tree_txt"
  : > "$restore_plan"
  : > "$dirty_file"
  : > "$unknown_hosts_file"
  : > "$no_remote_file"

  printf 'relative_path\tbranch\tprimary_remote\tscheme\thost\tstatus\trestorable\n' > "$repos_tsv"
  printf 'relative_path\tprimary_remote\n' > "$restore_plan"

  log "Scanning Git repos under: $CODE_DIR"
  find_git_repos "$CODE_DIR" "$repo_list_file"

  if [ ! -s "$repo_list_file" ]; then
    warn "No Git repositories found under $CODE_DIR"
    warn "Debug: check that CODE_DIR is correct. Current CODE_DIR=$CODE_DIR"
    return 0
  fi

  while IFS= read -r repo; do
    local rel branch remote scheme host status restorable
    rel="$(relative_to_code_dir "$repo")"
    branch="$(repo_current_branch "$repo")"
    remote="$(repo_primary_remote "$repo")"
    scheme=""
    host=""
    status="clean"
    restorable="yes"

    if [ -z "$remote" ]; then
      printf '%s\n' "$rel" >> "$no_remote_file"
      restorable="no"
    else
      scheme="$(remote_scheme_from_url "$remote")"
      host="$(remote_host_from_url "$remote" || true)"
      if [ "$scheme" = "ssh" ] && [ -n "$host" ] && ! ssh_host_known "$host"; then
        printf '%s\t%s\t%s\n' "$rel" "$host" "$remote" >> "$unknown_hosts_file"
        restorable="no"
      fi
    fi

    if repo_is_dirty "$repo"; then
      status="dirty"
      printf '%s\n' "$rel" >> "$dirty_file"
    fi

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$rel" "$branch" "$remote" "$scheme" "$host" "$status" "$restorable" >> "$repos_tsv"

    if [ "$restorable" = "yes" ] && [ -n "$remote" ]; then
      printf '%s\t%s\n' "$rel" "$remote" >> "$restore_plan"
    fi

    mkdir -p "$REPO_STRUCTURE_DIR/$rel"
    {
      printf 'relative_path=%s\n' "$rel"
      printf 'branch=%s\n' "$branch"
      printf 'primary_remote=%s\n' "$remote"
      printf 'scheme=%s\n' "$scheme"
      printf 'host=%s\n' "$host"
      printf 'status=%s\n' "$status"
      printf 'restorable=%s\n' "$restorable"
    } > "$REPO_STRUCTURE_DIR/$rel/.repo"
  done < "$repo_list_file"

  {
    printf '# Repositories found under ~/code\n\n'
    printf 'Generated: %s\n\n' "$(timestamp)"
    awk -F '\t' 'NR > 1 {
      printf "- %s\n  branch: %s\n  remote: %s\n  host: %s\n  status: %s\n  restorable: %s\n\n", $1, $2, $3, $5, $6, $7
    }' "$repos_tsv"
  } > "$repos_txt"

  {
    printf '# Directory structure under ~/code, stopping at Git repository roots\n\n'
    if command -v tree >/dev/null 2>&1; then
      tree "$REPO_STRUCTURE_DIR"
    else
      find "$REPO_STRUCTURE_DIR" -print | sed "s#^$REPO_STRUCTURE_DIR#.#"
    fi
  } > "$tree_txt"

  print_repo_summary "$repos_tsv" "$unknown_hosts_file" "$no_remote_file"

  if [ -s "$dirty_file" ]; then
    printf '\nRepositories with uncommitted changes:\n' >&2
    sed 's/^/- /' "$dirty_file" >&2
    fail "Backup stopped. Commit or stash these changes before continuing."
  fi
}

print_repo_summary() {
  local repos_tsv="$1"
  local unknown_hosts_file="$2"
  local no_remote_file="$3"

  printf '\nRepository summary\n'
  printf '==================\n\n'
  column -t -s $'\t' "$repos_tsv" 2>/dev/null || cat "$repos_tsv"

  if [ -s "$unknown_hosts_file" ]; then
    printf '\nWARNING: Some repositories use SSH hostnames not present in ~/.ssh/config.\n\n'
    column -t -s $'\t' "$unknown_hosts_file" 2>/dev/null || cat "$unknown_hosts_file"
    printf '\n'
  fi

  if [ -s "$no_remote_file" ]; then
    printf '\nWARNING: Some repositories have no remote and cannot be cloned after wipe:\n\n'
    sed 's/^/- /' "$no_remote_file"
    printf '\n'
  fi

  printf '\nRepositories planned for restore are listed in:\n'
  printf '  %s\n\n' "$REPOS_DIR/restore-plan.tsv"
}

backup_gpg() {
  log "Backing up GPG secret keys"

  if ! command -v gpg >/dev/null 2>&1; then
    warn "gpg command not found. Skipping GPG backup."
    return 0
  fi

  mkdir -p "$GPG_BACKUP_DIR"

  local secret_count
  secret_count="$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '$1 == "sec" { count++ } END { print count + 0 }')"

  if [ "$secret_count" -eq 0 ]; then
    warn "No GPG secret keys found. Skipping GPG key export."
    return 0
  fi

  gpg --armor --export-secret-keys > "$GPG_BACKUP_DIR/private-keys.asc"
  gpg --armor --export > "$GPG_BACKUP_DIR/public-keys.asc"
  gpg --export-ownertrust > "$GPG_BACKUP_DIR/ownertrust.txt" || true
  gpg --list-secret-keys --keyid-format=long > "$GPG_BACKUP_DIR/secret-keys.list.txt"

  chmod 700 "$GPG_BACKUP_DIR"
  chmod 600 "$GPG_BACKUP_DIR"/* 2>/dev/null || true
}

backup_ssh() {
  log "Backing up ~/.ssh"

  if [ ! -d "$HOME/.ssh" ]; then
    warn "~/.ssh does not exist. Skipping SSH backup."
    return 0
  fi

  mkdir -p "$SSH_BACKUP_DIR"

  rsync -a     --exclude='*.sock'     --exclude='control-*'     "$HOME/.ssh/" "$SSH_BACKUP_DIR/"

  find "$HOME/.ssh" -mindepth 1 -maxdepth 2 -print0 2>/dev/null |
    while IFS= read -r -d '' file; do
      rel="${file#$HOME/.ssh/}"
      mode="$(stat -f '%OLp' "$file" 2>/dev/null || true)"
      printf '%s\t%s\n' "$rel" "$mode"
    done > "$SSH_BACKUP_DIR/permissions.tsv"

  chmod 700 "$SSH_BACKUP_DIR"
  find "$SSH_BACKUP_DIR" -type d -exec chmod 700 {} \;
  find "$SSH_BACKUP_DIR" -type f -exec chmod go-rwx {} \;
}

extract_sourced_home_files_from_zshrc() {
  local zshrc="$HOME/.zshrc"
  local output="$REPORTS_DIR/zsh-sourced-home-files.txt"
  : > "$output"

  [ -f "$zshrc" ] || return 0

  while IFS= read -r line; do
    line="${line%%#*}"

    if [[ "$line" =~ (^|[[:space:]]|\&\&)(source|\.)[[:space:]]+([^[:space:];]+) ]]; then
      token="${BASH_REMATCH[3]}"
      token="${token%\"}"
      token="${token#\"}"
      token="${token%\'}"
      token="${token#\'}"
      token="${token//\$HOME/$HOME}"
      token="${token/#\~/$HOME}"

      if [[ "$token" == "$HOME/"* ]]; then
        case "$token" in
          "$HOME/.oh-my-zsh/"*|"$HOME/.nvm/"*|"$HOME/.bun/"*) continue ;;
        esac
        printf '%s\n' "$token" >> "$output"
      fi
    fi
  done < "$zshrc"

  sort -u "$output" -o "$output"
}

backup_personal_scripts() {
  log "Backing up personal scripts sourced from ~/.zshrc"

  local sourced_file="$REPORTS_DIR/zsh-sourced-home-files.txt"
  local manifest="$HOME_FILES_DIR/manifest.tsv"
  : > "$manifest"

  extract_sourced_home_files_from_zshrc

  if [ ! -s "$sourced_file" ]; then
    warn "No sourced personal home files detected in ~/.zshrc"
    return 0
  fi

  while IFS= read -r path; do
    if [ ! -e "$path" ]; then
      printf '%s\tmissing\n' "${path#$HOME/}" >> "$manifest"
      continue
    fi

    rel="${path#$HOME/}"
    mkdir -p "$HOME_FILES_DIR/$(dirname "$rel")"

    if [ -f "$path" ]; then
      cp -p "$path" "$HOME_FILES_DIR/$rel"
    elif [ -d "$path" ]; then
      rsync -a "$path/" "$HOME_FILES_DIR/$rel/"
    fi

    mode="$(stat -f '%OLp' "$path" 2>/dev/null || true)"
    printf '%s\t%s\n' "$rel" "$mode" >> "$manifest"
  done < "$sourced_file"
}

backup_misc_metadata() {
  log "Backing up local metadata/reports"

  {
    printf '# Environment variable names present during backup\n'
    printf '# Values are intentionally not stored.\n\n'
    env | awk -F= '{ print $1 }' | sort -u
  } > "$REPORTS_DIR/environment-variable-names.txt"

  {
    printf '# keyvalue.txt\n'
    printf '# Optional local-only secret store.\n'
    printf '# Do not commit this file. Keep it inside secrets/ only.\n'
    printf '# Format:\n'
    printf '# NAME=value\n\n'
    printf '# Example:\n'
    printf '# SOME_TOKEN=replace-me\n'
  } > "$SECRETS_DIR/keyvalue.txt"

  [ -f "$HOME/.gitconfig" ] && cp -p "$HOME/.gitconfig" "$REPORTS_DIR/gitconfig.current.backup" || true
  [ -f "$HOME/.zshrc" ] && cp -p "$HOME/.zshrc" "$REPORTS_DIR/zshrc.current.backup" || true

  if command -v brew >/dev/null 2>&1; then
    brew list --formula > "$REPORTS_DIR/brew-formulas.current.txt" 2>/dev/null || true
    brew list --cask > "$REPORTS_DIR/brew-casks.current.txt" 2>/dev/null || true
  fi
}

backup_iterm2() {
  log "Backing up iTerm2 configuration"

  local src="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
  local dest_dir="$SECRETS_DIR/app-configs/iterm2"

  mkdir -p "$dest_dir"

  if [ -f "$src" ]; then
    cp -p "$src" "$dest_dir/com.googlecode.iterm2.plist"
  else
    warn "iTerm2 preferences not found at $src"
  fi

  # Optional: backup color preset files if you keep them somewhere predictable.
  if [ -d "$HOME/Library/Application Support/iTerm2" ]; then
    rsync -a \
      "$HOME/Library/Application Support/iTerm2/" \
      "$dest_dir/Application Support iTerm2/" \
      2>/dev/null || true
  fi
}

backup_widgets() {
  log "Backing up macOS widgets / Notification Center configuration"

  local dest="$SECRETS_DIR/app-configs/widgets"
  mkdir -p "$dest"

  copy_if_exists() {
    local src="$1"
    local name="$2"

    if [ -e "$src" ]; then
      rsync -a "$src" "$dest/$name" 2>/dev/null || true
    fi
  }

  copy_if_exists "$HOME/Library/Group Containers/group.com.apple.widgets" "group.com.apple.widgets"
  copy_if_exists "$HOME/Library/Preferences/com.apple.notificationcenterui.plist" "com.apple.notificationcenterui.plist"
  copy_if_exists "$HOME/Library/Preferences/com.apple.widgets.plist" "com.apple.widgets.plist"
  copy_if_exists "$HOME/Library/Application Support/NotificationCenter" "NotificationCenter"
}

final_summary() {
  printf '\nBackup summary\n'
  printf '==============\n\n'
  printf 'Secrets folder:\n  %s\n\n' "$SECRETS_DIR"
  printf 'Saved repo inventory:\n  %s\n  %s\n  %s\n\n' "$REPOS_DIR/repos.txt" "$REPOS_DIR/restore-plan.tsv" "$REPOS_DIR/tree.txt"
  printf 'Saved SSH backup:\n  %s\n\n' "$SSH_BACKUP_DIR"
  printf 'Saved GPG backup:\n  %s\n\n' "$GPG_BACKUP_DIR"
  printf 'Saved personal home files/scripts:\n  %s\n\n' "$HOME_FILES_DIR"
  printf 'Saved reports:\n  %s\n\n' "$REPORTS_DIR"

  if command -v tree >/dev/null 2>&1; then
    printf 'Generated secrets tree:\n\n'
    tree "$SECRETS_DIR"
  else
    printf 'Generated secrets files:\n\n'
    find "$SECRETS_DIR" -print | sed "s#^$SECRETS_DIR#secrets#"
  fi

  printf '\nSUCCESS: Backup completed.\n\n'
  printf 'Next step: copy the entire secrets/ folder to a safe offline location,\n'
  printf 'preferably an offline USB drive. This folder contains private SSH/GPG material.\n'
  printf 'Never commit it and never upload it to a public repo.\n\n'
}

main() {
  log "Starting backup"

  if [ -d "$DOWNLOADS_DIR" ] && ! is_downloads_effectively_empty "$DOWNLOADS_DIR"; then
    warn "$DOWNLOADS_DIR is not empty. Downloads is usually not cloud-synced. Review it before wiping this Mac."
    if ! confirm "Continue backup anyway?"; then
      fail "Backup cancelled so you can review Downloads first."
    fi
  fi

  load_ssh_host_aliases
  make_repo_reports

  printf '\nThe repo inventory is clean enough to continue.\n'
  if ! confirm "Continue and export/copy sensitive SSH and GPG secrets into $SECRETS_DIR?"; then
    fail "Backup cancelled before exporting secrets."
  fi

  backup_gpg
  backup_ssh
  backup_personal_scripts
  backup_misc_metadata
  backup_iterm2
  backup_widgets
  final_summary
}

main "$@"
