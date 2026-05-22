# Eduardo macOS Nix Restore

Declarative macOS setup for a clean MacBook reinstall using:

- Nix flakes
- nix-darwin
- Home Manager
- nix-homebrew
- Homebrew casks/formulas
- local offline `secrets/` restore folder

This repo is designed to be public-safe. The real `secrets/` folder is ignored by Git and should be kept offline, preferably on a USB drive.

## First-time backup, before wiping the Mac

Run this from the repo root:

```sh
chmod +x scripts/*.sh
./scripts/backup.sh
```

The script creates:

```txt
secrets/
├── gpg/
├── ssh/
├── home-files/
├── repos/
├── reports/
└── keyvalue.txt
```

Copy the entire `secrets/` folder to an offline USB drive.

## Restore after clean macOS install

Manual prerequisites:

1. Sign in to iCloud.
2. Install Xcode Command Line Tools:

```sh
xcode-select --install
```

3. Clone this public repo.
4. Copy your offline `secrets/` folder into the repo root.
5. Run:

```sh
chmod +x scripts/*.sh
./scripts/bootstrap.sh
```

The bootstrap script will:

- install Nix if needed
- apply nix-darwin configuration
- restore SSH keys if `secrets/ssh` exists
- restore GPG keys if `secrets/gpg` exists
- restore personal sourced shell files if `secrets/home-files` exists
- restore Git repositories from `secrets/repos/restore-plan.tsv`
- copy `todo.md` to the Desktop
- open the Desktop TODO in VSCode if `code` is available

## Normal apply after bootstrap

```sh
./scripts/apply.sh
```

## Important safety rule

Never commit `secrets/`.

This repo may be public, but `secrets/` contains private SSH/GPG material.
