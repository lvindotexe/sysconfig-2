# AGENTS.md

This repository is a Nix flake containing a Home Manager configuration (Darwin).
It is intended to be evaluated/applied with `nix` + `home-manager`.

No Cursor rules (`.cursor/rules/` or `.cursorrules`) or Copilot rules
(`.github/copilot-instructions.md`) are present in this repo.

## Quick Commands

### Build

- Build the Home Manager activation package:
  - `nix build .#homeConfigurations.alvinv.activationPackage`
  - With logs: `nix build -L --print-build-logs .#homeConfigurations.alvinv.activationPackage`

- Show flake outputs:
  - `nix flake show`
  - Machine-readable: `nix flake show --json`

### Check / Lint

- Run all flake checks (closest thing to “lint” here):
  - `nix flake check -L`
  - With full logs: `nix flake check -L --print-build-logs`

- Evaluate a single attribute (fast sanity check):
  - `nix eval .#homeConfigurations.alvinv.config.home.stateVersion`
  - `nix eval .#homeConfigurations.alvinv.config.programs.git.enable`

### Apply (be careful)

- Dry run (preferred for agents):
  - `home-manager switch --flake .#alvinv --dry-run`

- Actually apply (only when requested by the user):
  - `home-manager switch --flake .#alvinv`

### “Run a Single Test” Equivalent

There are no unit-test suites in this repo. The closest equivalents are:

- Build just one output (single “test”):
  - `nix build .#homeConfigurations.alvinv.activationPackage`

- Evaluate just one option/attr to narrow failures:
  - `nix eval .#homeConfigurations.alvinv.config.<path.to.option>`

- Run one check derivation (when available):
  - `nix build .#checks.aarch64-darwin.<checkName>`
  - Discover names via `nix flake show`.

## Repository Layout

- `flake.nix`: flake entrypoint; defines `homeConfigurations.alvinv`.
- `home.nix`: Home Manager module (the main config).
- `loki.nix`: separate flake wrapping `vf-loki` as a package/app.
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
- Don’t introduce evaluation-time failures for optional tools.

### Imports and String Interpolation

- Prefer `${...}` interpolation over manual concatenation.
- Use `'' ... ''` multiline strings for embedded shell snippets.
- Inside `'' ... ''`, keep indentation consistent and avoid trailing whitespace.

### Comments

- Keep comments short and high-signal: explain “why”, not “what”.
- Prefer removing stale comments over expanding them.

## Agent Workflow Expectations

- Prefer `nix eval` and `nix build` for validation.
- Do not run `home-manager switch` without explicit user approval; use
  `--dry-run` for safety.
- Avoid changing user-specific constants unless asked:
  - `home.username`, `home.homeDirectory`, `system` in `flake.nix`.
- Avoid non-determinism: no network fetches outside Nix flakes; prefer pinned
  inputs and flake locks.

## Review Checklist (Before Sending PR/Changes)

- `nix flake check -L` passes (or explain what is not applicable).
- `nix build .#homeConfigurations.alvinv.activationPackage` succeeds.
- New options follow existing grouping and indentation.
- No references to missing files without guards.
- Any changes to `dotfiles/` are referenced from `home.nix`.
