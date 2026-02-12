#!/usr/bin/env bash
set -euo pipefail

REPO_URL_DEFAULT="https://github.com/lvindotexe/sysconfig-2.git"
REPO_DIR_DEFAULT="${HOME}/.local/share/sysconfig-2"

repo_url="${REPO_URL_DEFAULT}"
repo_dir="${REPO_DIR_DEFAULT}"
dry_run="0"

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--repo <git-url>] [--repo-dir <path>] [--dry-run]

Detects how Nix is installed (standalone, nix-darwin, NixOS) and sets
up Home Manager accordingly.

Examples:
  bootstrap.sh
  bootstrap.sh --dry-run
  bootstrap.sh --repo-dir ~/dotfiles
EOF
}

log() {
  printf '[bootstrap] %s\n' "$*" >&2
}

die() {
  printf '[bootstrap] error: %s\n' "$*" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# Host detection
# ---------------------------------------------------------------------------

detect_host() {
  HOST_OS="$(uname -s)"
  HOST_ARCH="$(uname -m)"

  case "${HOST_ARCH}" in
    x86_64|amd64)  HOST_ARCH="x86_64"  ;;
    aarch64|arm64)  HOST_ARCH="aarch64" ;;
    *)              die "unsupported architecture: ${HOST_ARCH}" ;;
  esac

  HOST_WSL=0
  if [[ "${HOST_OS}" == "Linux" ]] && grep -qi 'microsoft' /proc/version 2>/dev/null; then
    HOST_WSL=1
    log "WSL detected"
  fi

  log "Host: ${HOST_OS} ${HOST_ARCH}"
}

# Determine how Nix is present on this machine.
# Sets NIX_METHOD to one of: none, standalone, nix-darwin, nixos
detect_nix_method() {
  if ! command -v nix >/dev/null 2>&1; then
    NIX_METHOD="none"
    return
  fi

  if [[ -f /run/current-system/darwin-version ]]; then
    NIX_METHOD="nix-darwin"
  elif [[ -f /etc/NIXOS ]] || [[ -f /run/current-system/nixos-version ]]; then
    NIX_METHOD="nixos"
  else
    NIX_METHOD="standalone"
  fi

  log "Nix method: ${NIX_METHOD}"
}

# ---------------------------------------------------------------------------
# Installation
# ---------------------------------------------------------------------------

ensure_nix() {
  if command -v nix >/dev/null 2>&1; then
    return
  fi

  command -v curl >/dev/null 2>&1 || die "curl is required to install Nix"

  log "Nix not found. Installing via nix-installer"
  curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --no-confirm

  if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck source=/dev/null
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  elif [[ -r "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]]; then
    # shellcheck source=/dev/null
    . "${HOME}/.nix-profile/etc/profile.d/nix.sh"
  fi

  command -v nix >/dev/null 2>&1 || die "Nix installation finished but nix is still unavailable"

  # Re-detect now that Nix is available
  detect_nix_method
}

ensure_homebrew() {
  if [[ "${HOST_OS}" != "Darwin" ]]; then
    return
  fi

  if command -v brew >/dev/null 2>&1; then
    return
  fi

  command -v curl >/dev/null 2>&1 || die "curl is required to install Homebrew"

  log "Homebrew not found. Installing..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ "${HOST_ARCH}" == "aarch64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  command -v brew >/dev/null 2>&1 || die "Homebrew installation finished but brew is still unavailable"
}

ensure_repo() {
  command -v git >/dev/null 2>&1 || die "git is required"

  mkdir -p "$(dirname "${repo_dir}")"

  if [[ -d "${repo_dir}/.git" ]]; then
    log "Using existing repo at ${repo_dir}"
    if git -C "${repo_dir}" diff --quiet && git -C "${repo_dir}" diff --cached --quiet; then
      git -C "${repo_dir}" pull --ff-only || log "Could not fast-forward; continuing with existing checkout"
    else
      log "Local changes detected; skipping git pull"
    fi
    return
  fi

  if [[ -e "${repo_dir}" ]]; then
    die "${repo_dir} exists but is not a git repo"
  fi

  log "Cloning ${repo_url} to ${repo_dir}"
  git clone "${repo_url}" "${repo_dir}"
}

# ---------------------------------------------------------------------------
# Local config
# ---------------------------------------------------------------------------

write_local_config() {
  local config_file="${repo_dir}/local.nix"

  if [[ -f "${config_file}" ]]; then
    log "local.nix already exists; skipping"
    return
  fi

  local hostname
  hostname="$(hostname -s 2>/dev/null || hostname)"

  local username="${USER:-$(whoami)}"

  local system
  case "${HOST_OS}" in
    Darwin) system="${HOST_ARCH}-darwin" ;;
    Linux)  system="${HOST_ARCH}-linux" ;;
    *)      die "unsupported OS: ${HOST_OS}" ;;
  esac

  local platform
  case "${HOST_OS}" in
    Darwin) platform="darwin" ;;
    Linux)
      if [[ "${NIX_METHOD}" == "nixos" ]]; then
        platform="nixos"
      else
        platform="linux"
      fi
      ;;
  esac

  log "Writing local.nix (hostname=${hostname}, system=${system})"
  cat > "${config_file}" <<LOCALEOF
{
  hostname = "${hostname}";
  username = "${username}";
  system = "${system}";
  platform = "${platform}";
}
LOCALEOF
}

# ---------------------------------------------------------------------------
# Apply
# ---------------------------------------------------------------------------

apply() {
  local flake_ref="path:${repo_dir}"

  case "${HOST_OS}" in
    Darwin)
      local machine_hostname
      machine_hostname="$(hostname -s 2>/dev/null || hostname)"

      if command -v darwin-rebuild >/dev/null 2>&1; then
        local cmd=(darwin-rebuild switch --flake "${flake_ref}#${machine_hostname}")
        if [[ "${dry_run}" == "1" ]]; then
          cmd+=(--dry-run)
        fi
        log "Applying darwin configuration: ${machine_hostname}"
        "${cmd[@]}"
      else
        local cmd=(
          nix
          --extra-experimental-features "nix-command flakes"
          run nix-darwin --
          switch --flake "${flake_ref}#${machine_hostname}"
        )
        if [[ "${dry_run}" == "1" ]]; then
          cmd+=(--dry-run)
        fi
        log "First run — bootstrapping nix-darwin for: ${machine_hostname}"
        "${cmd[@]}"
      fi
      ;;

    Linux)
      if [[ "${NIX_METHOD}" == "nixos" ]]; then
        local machine_hostname
        machine_hostname="$(hostname -s 2>/dev/null || hostname)"

        local cmd=(sudo nixos-rebuild switch --flake "${flake_ref}#${machine_hostname}")
        if [[ "${dry_run}" == "1" ]]; then
          cmd+=(--dry-run)
        fi
        log "Applying NixOS configuration: ${machine_hostname}"
        "${cmd[@]}"
        return
      fi

      local username="${USER:-user}"

      if command -v home-manager >/dev/null 2>&1; then
        local cmd=(home-manager switch --flake "${flake_ref}#${username}")
        if [[ "${dry_run}" == "1" ]]; then
          cmd+=(--dry-run)
        fi
        log "Applying home-manager configuration: ${username}"
        "${cmd[@]}"
      else
        local cmd=(
          nix
          --extra-experimental-features "nix-command flakes"
          run home-manager/master --
          -b hm-bak switch
          --flake "${flake_ref}#${username}"
        )
        if [[ "${dry_run}" == "1" ]]; then
          cmd+=(--dry-run)
        fi
        log "First run — bootstrapping home-manager for: ${username}"
        "${cmd[@]}"
      fi
      ;;

    *)
      die "unsupported OS: ${HOST_OS}"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ $# -ge 2 ]] || die "--repo requires a value"
      repo_url="$2"
      shift 2
      ;;
    --repo-dir)
      [[ $# -ge 2 ]] || die "--repo-dir requires a value"
      repo_dir="$2"
      shift 2
      ;;
    --dry-run)
      dry_run="1"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

detect_host
detect_nix_method
ensure_nix
ensure_homebrew
ensure_repo
write_local_config
apply

log "Done"
