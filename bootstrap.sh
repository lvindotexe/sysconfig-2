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
  bootstrap.sh --profile linux
  bootstrap.sh --profile darwin --dry-run
EOF
}

log() {
  printf '[bootstrap] %s\n' "$*"
}

die() {
  printf '[bootstrap] error: %s\n' "$*" >&2
  exit 1
}

detect_default_profile() {
  case "$(uname -s)" in
    Darwin)
      printf 'darwin\n'
      ;;
    Linux)
      printf 'linux\n'
      ;;
    *)
      die "unsupported OS: $(uname -s)"
      ;;
  esac
}

ensure_nix() {
  if command -v nix >/dev/null 2>&1; then
    return
  fi

  command -v curl >/dev/null 2>&1 || die "curl is required to install Nix"

  log "Nix not found. Installing via Determinate installer"
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm

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
    switch
    --flake
    "${repo_dir}#${profile}"
    --backup-file-extension
    hm-bak
  )

  if [[ "${dry_run}" == "1" ]]; then
    hm_cmd+=(--dry-run)
  fi

  hm_cmd+=(--impure)

  log "Applying profile ${profile}"
  "${hm_cmd[@]}"
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

ensure_nix
ensure_repo
run_home_manager

log "Done"
