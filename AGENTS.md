# AGENTS.md

This repository is a Nix flake containing a unified nix-darwin + Home Manager
configuration. On macOS it produces `darwinConfigurations`; on Linux it produces
standalone `homeConfigurations` or exports a module for NixOS.

## Quick Commands

### Build

- Build the darwin system (macOS):
  - `nix build .#darwinConfigurations.AMS-OFFICE145.system`
  - With logs: `nix build -L --print-build-logs .#darwinConfigurations.AMS-OFFICE145.system`

- Build standalone Home Manager (Linux):
  - `nix build .#homeConfigurations.alvinv.activationPackage`

- Show flake outputs:
  - `nix flake show`
  - Machine-readable: `nix flake show --json`

### Check / Lint

- Run all flake checks:
  - `nix flake check -L`

- Evaluate a single attribute:
  - `nix eval .#darwinConfigurations.AMS-OFFICE145.config.system.stateVersion`
  - `nix eval .#homeConfigurations.alvinv.config.programs.git.enable`

### Apply (be careful)

- Dry run (preferred for agents):
  - macOS: `darwin-rebuild switch --flake .#AMS-OFFICE145 --dry-run`
  - Linux: `home-manager switch --flake .#alvinv --dry-run`

- Actually apply (only when requested by the user):
  - macOS: `darwin-rebuild switch --flake .#AMS-OFFICE145`
  - Linux: `home-manager switch --flake .#alvinv`

### "Run a Single Test" Equivalent

There are no unit-test suites in this repo. The closest equivalents are:

- Build just one output:
  - `nix build .#darwinConfigurations.AMS-OFFICE145.system`

- Evaluate just one option:
  - `nix eval .#darwinConfigurations.AMS-OFFICE145.config.<path.to.option>`

## Repository Layout

- `flake.nix`: flake entrypoint; defines `darwinConfigurations`, `homeConfigurations`, `homeManagerModules`.
- `home.nix`: shared Home Manager module (portable across all modes).
- `hosts/darwin.nix`: nix-darwin system configuration (macOS).
- `bootstrap.sh`: host-aware setup script.
- `modules/shell/`: modular shell configuration (common, bash, zsh, aliases).
- `dotfiles/`: managed dotfiles referenced by `home.nix`.

## Code Style Guidelines

### Nix Formatting

- Indentation: 2 spaces.
- Use trailing semicolons for attribute assignments.
- Prefer one attribute per line in large attrsets.
- Keep `{ config, pkgs, lib, ... }:` argument set sorted and minimal.
- Use `let ... in` for local bindings; keep `let` blocks small and focused.
- Prefer `inherit` when passing through values (`inherit pkgs;`).

### Imports / Modules

- Prefer explicit module paths in `modules = [ ... ];` lists.
- Keep module lists stable and deterministic (avoid conditional insertion when
  a `lib.mkIf` inside the module can do the job).
- When adding new modules, name files after the domain (`git.nix`, `zsh.nix`,
  `devtools.nix`) and keep them cohesive.

### Option / Attrset Organization

- Group options by feature (shell, git, editor, terminal, etc.).
- Keep high-level `home.*` options near the top.
- Prefer `programs.<name> = { enable = true; ... };` blocks over scattered
  individual options.
- Keep long lists (`home.packages`) sorted roughly by category with short
  category spacing (as already used).

### Naming Conventions

- Use `camelCase` for local Nix bindings.
- Use descriptive names; avoid single-letter bindings except in tiny lambdas.
- Keep identifiers ASCII.

### Types / Values

- Prefer Nix-native types:
  - lists `[...]`, attrsets `{ ... }`, strings `"..."`, paths `./relative/path`.
- Use `builtins.pathExists` for optional files.
- For config-derived paths, prefer `${config.home.homeDirectory}/...`.

### Error Handling / Safety

- Favor configuration that degrades gracefully:
  - Gate optional features with `lib.mkIf` or `builtins.pathExists`.
- When referencing external files, ensure they exist or are guarded.
- Don't introduce evaluation-time failures for optional tools.

### Imports and String Interpolation

- Prefer `${...}` interpolation over manual concatenation.
- Use `'' ... ''` multiline strings for embedded shell snippets.
- Inside `'' ... ''`, keep indentation consistent and avoid trailing whitespace.

### Comments

- Keep comments short and high-signal: explain "why", not "what".
- Prefer removing stale comments over expanding them.

## Agent Workflow Expectations

- Prefer `nix eval` and `nix build` for validation.
- Do not run `darwin-rebuild switch` or `home-manager switch` without explicit
  user approval; use `--dry-run` for safety.
- Avoid non-determinism: no network fetches outside Nix flakes; prefer pinned
  inputs and flake locks.

## Review Checklist (Before Sending PR/Changes)

- `nix flake check -L` passes (or explain what is not applicable).
- Relevant build target succeeds (darwin system or HM activation package).
- New options follow existing grouping and indentation.
- No references to missing files without guards.
- Any changes to `dotfiles/` are referenced from `home.nix`.
