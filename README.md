# sysconfig-2

Opinionated Home Manager flake for daily dev environments on macOS and Linux.

This repo declaratively manages shell setup, editor/tooling, Git/GitHub CLI, tmux, and related dotfiles. Home Manager evaluates the flake, builds a generation in `/nix/store`, and links managed files into your home directory.

## Installation

### Quick install (recommended)

Use the bootstrap script on a fresh machine:

```bash
./bootstrap.sh
```

What it does:

- Installs Nix if needed.
- Clones this repo to `${XDG_CONFIG_HOME:-~/.config}/home-manager` (or `--hm-root`).
- Detects your profile (`darwin-aarch64`, `linux-x86_64`, etc.).
- Creates `local.nix` with username/home overrides if missing.
- Runs Home Manager switch with backup extension `hm-bak`.

Useful flags:

```bash
./bootstrap.sh --dry-run
./bootstrap.sh --profile linux-x86_64
./bootstrap.sh --hm-root ~/.config/home-manager
./bootstrap.sh --repo https://github.com/<you>/<fork>.git
```

### Manual install

If you already have Nix/Home Manager tooling and want direct control:

```bash
# from the repo root
home-manager switch --flake .#darwin-aarch64
# or
home-manager switch --flake .#linux-x86_64
```

Auto-detect current user/profile (impure eval):

```bash
home-manager switch --impure --flake .
```

Safe first run:

```bash
home-manager switch --impure --flake . --dry-run
```

## Usage

Common workflows after install:

```bash
# see available outputs
nix flake show

# fast sanity checks
nix eval .#homeConfigurations.linux-x86_64.config.home.stateVersion

# build only the activation package
nix build .#homeConfigurations.linux-x86_64.activationPackage

# run full checks
nix flake check -L

# apply changes
home-manager switch --flake .#linux-x86_64

# rollback
home-manager generations
home-manager switch --rollback
```

Profile names:

```text
aarch64-darwin -> darwin-aarch64
x86_64-darwin  -> darwin-x86_64
x86_64-linux   -> linux-x86_64
aarch64-linux  -> linux-aarch64
```

Compatibility aliases:

- `darwin` -> `darwin-aarch64`
- `linux` -> `linux-x86_64`

## Quirks and gotchas

1) `--flake` takes a directory, not `flake.nix`

```bash
# bad
home-manager switch --flake flake.nix

# good
home-manager switch --flake .#linux-x86_64
```

2) `~/.config/home-manager` can be empty and things still work

Flake mode evaluates whichever path you pass to `--flake`; it does not require this repo to live at `~/.config/home-manager`.

3) `Git tree is dirty` during eval/build

This is informational. It means the repo has uncommitted changes, not that evaluation failed.

4) `gh auth login` can fail with `hosts.yml: permission denied`

`programs.gh.hosts` declaratively writes `~/.config/gh/hosts.yml` as a store-backed symlink, so `gh` cannot modify it interactively.

Workarounds:

- Manage auth token outside declarative `hosts.yml`, or
- Temporarily adjust/remove `programs.gh.hosts` before interactive login.

5) First switch may collide with existing dotfiles

Use backup extension when applying manually:

```bash
home-manager switch --flake .#linux-x86_64 -b hm-bak
```

## Repo layout

- `flake.nix` - flake inputs/outputs and profile matrix.
- `home.nix` - main Home Manager module.
- `modules/shell/` - shell modules (common/bash/zsh/aliases).
- `dotfiles/` - managed config fragments.
- `local.nix.example` - sample machine-local overrides.
- `bootstrap.sh` - bootstrap flow for new machines.
