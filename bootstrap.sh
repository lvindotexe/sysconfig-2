#!/usr/bin/env bash
set -euo pipefail

REPO_URL_DEFAULT="https://github.com/lvindotexe/sysconfig-2.git"
REPO_DIR_DEFAULT="${HOME}/.local/share/sysconfig-2"

repo_url="${REPO_URL_DEFAULT}"
repo_dir="${REPO_DIR_DEFAULT}"
profile=""
dry_run="0"

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [--profile <name>] [--repo <git-url>] [--repo-dir <path>] [--dry-run]

Examples:
  bootstrap.sh
  bootstrap.sh --profile linux-x86_64
  bootstrap.sh --profile darwin-aarch64 --dry-run
EOF
}

log() {
  printf '[bootstrap] %s\n' "$*" >&2
}

die() {
  printf '[bootstrap] error: %s\n' "$*" >&2
  exit 1
}

detect_default_profile() {
  local os
  local arch

  os="$(uname -s)"
  arch="$(uname -m)"

  case "${arch}" in
    x86_64|amd64)
      arch="x86_64"
      ;;
    aarch64|arm64)
      arch="aarch64"
      ;;
    *)
      die "unsupported architecture: ${arch}"
      ;;
  esac

  case "${os}" in
    Darwin)
      printf 'darwin-%s\n' "${arch}"
      ;;
    Linux)
      if grep -qi 'microsoft' /proc/version 2>/dev/null; then
        log "WSL detected; using linux-${arch} profile"
      fi
      printf 'linux-%s\n' "${arch}"
      ;;
    *)
      die "unsupported OS: ${os}"
      ;;
  esac
}

ensure_nix() {
  if command -v nix >/dev/null 2>&1; then
    return
  fi

  command -v curl >/dev/null 2>&1 || die "curl is required to install Nix"

  log "Nix not found. Installing via NixOS nix-installer"
  curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --no-confirm

  if [[ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck source=/dev/null
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  elif [[ -r "${HOME}/.nix-profile/etc/profile.d/nix.sh" ]]; then
    # shellcheck source=/dev/null
    . "${HOME}/.nix-profile/etc/profile.d/nix.sh"
  fi

  command -v nix >/dev/null 2>&1 || die "Nix installation finished but nix is still unavailable"
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

run_home_manager() {
  local hm_cmd
  hm_cmd=(
    nix
    --extra-experimental-features
    "nix-command flakes"
    run
    home-manager/master
    --
    -b
    hm-bak
    switch
    --flake
    "path:${repo_dir}#${profile}"
  )

  if [[ "${dry_run}" == "1" ]]; then
    hm_cmd+=(--dry-run)
  fi

  log "Applying profile ${profile}"
  "${hm_cmd[@]}"
}

ensure_local_config() {
  local local_config
  local username
  local home_dir
  local darwin_home
  local linux_home

  local_config="${repo_dir}/local.nix"

  if [[ -f "${local_config}" ]]; then
    return
  fi

  username="${USER:-}"
  home_dir="${HOME:-}"

  [[ -n "${username}" ]] || die "USER is required to generate local.nix"
  [[ -n "${home_dir}" ]] || die "HOME is required to generate local.nix"

  darwin_home="/Users/${username}"
  linux_home="/home/${username}"

  case "$(uname -s)" in
    Darwin)
      darwin_home="${home_dir}"
      ;;
    Linux)
      linux_home="${home_dir}"
      ;;
  esac

  cat >"${local_config}" <<EOF
{
  defaults = {
    username = "${username}";
  };

  profiles = {
    darwin-aarch64 = {
      homeDirectory = "${darwin_home}";
    };

    darwin-x86_64 = {
      homeDirectory = "${darwin_home}";
    };

    linux-x86_64 = {
      homeDirectory = "${linux_home}";
    };

    linux-aarch64 = {
      homeDirectory = "${linux_home}";
    };
  };
}
EOF

  log "Created ${local_config}; adjust it if any profile needs a different path"
}

normalize_profile() {
  case "${profile}" in
    darwin)
      profile="darwin-aarch64"
      ;;
    linux)
      profile="linux-x86_64"
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      [[ $# -ge 2 ]] || die "--profile requires a value"
      profile="$2"
      shift 2
      ;;
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

if [[ -z "${profile}" ]]; then
  profile="$(detect_default_profile)"
fi

normalize_profile

ensure_nix
ensure_repo
ensure_local_config
run_home_manager

log "Done"
