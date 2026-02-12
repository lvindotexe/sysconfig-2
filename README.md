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
- Clones this repo to `~/.local/share/sysconfig-2`.
- On macOS: bootstraps nix-darwin (which includes Home Manager).
- On Linux: bootstraps standalone Home Manager.
- On NixOS: prints instructions to add the Home Manager module.

Useful flags:

```bash
./bootstrap.sh --dry-run
./bootstrap.sh --repo-dir ~/dotfiles
./bootstrap.sh --repo https://github.com/<you>/<fork>.git
```

### Manual install

If you already have the tooling installed:

```bash
# macOS (nix-darwin)
darwin-rebuild switch --flake .

# Linux (standalone home-manager)
home-manager switch --flake .
```

Both commands auto-select the right output key (`$(hostname -s)` for darwin, `$USER` for home-manager).

## Usage

Common workflows after install:

```bash
# see available outputs
nix flake show

# fast sanity checks
nix eval .#homeConfigurations.alvinv.config.home.stateVersion

# build only (no activation)
nix build .#darwinConfigurations.AMS-OFFICE145.system
nix build .#homeConfigurations.alvinv.activationPackage

# run full checks
nix flake check -L

# apply changes
darwin-rebuild switch --flake .          # macOS
home-manager switch --flake .            # Linux

# rollback
home-manager generations
home-manager switch --rollback
```

## Adding a new machine

Add an entry to `flake.nix`:

```nix
darwinConfigurations."NEW-HOSTNAME" = mkDarwin {
  system = "aarch64-darwin";
  username = "your-user";
};
```

Or for standalone Linux:

```nix
homeConfigurations."your-user" = mkStandaloneHome {
  system = "x86_64-linux";
  username = "your-user";
};
```

## Quirks and gotchas

1) `--flake` takes a directory, not `flake.nix`

```bash
# bad
home-manager switch --flake flake.nix

# good
home-manager switch --flake .
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
home-manager switch --flake . -b hm-bak
```

## Repo layout

- `flake.nix` - flake inputs/outputs; hosts and users defined inline.
- `home.nix` - main Home Manager module.
- `hosts/darwin.nix` - nix-darwin system configuration (macOS).
- `modules/shell/` - shell modules (common/bash/zsh/aliases).
- `dotfiles/` - managed config fragments.
- `bootstrap.sh` - bootstrap flow for new machines.
