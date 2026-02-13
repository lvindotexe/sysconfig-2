{ config, pkgs, lib, worktrunk, ... }:

{
  imports = [
    ./modules/shell/common.nix
    ./modules/shell/bash.nix
    ./modules/shell/zsh.nix
    ./modules/git.nix
    ./modules/nvf.nix
    ./modules/tmux.nix
    ./modules/ghostty.nix
  ];

  xdg.enable = true;

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.sessionVariables = {
    CLICOLOR = "1";
    LESS = "-FRX";
    PAGER = "less";
    EDITOR = "nvim";
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";
  };

  home.sessionPath = [
    "/etc/profiles/per-user/${config.home.username}/bin"
    "${config.home.homeDirectory}/.nix-profile/bin"
    "/nix/var/nix/profiles/default/bin"
    "${config.home.homeDirectory}/.local/bin"
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    "/run/current-system/sw/bin"
  ];

  home.packages = [
    worktrunk.packages.${pkgs.system}.default
  ] ++ (with pkgs; [
    bat
    jq
    ripgrep
    vim

    deno
    nodejs_25
    go
    bun

    docker
    ffmpeg
    htop
    tree
    moreutils
    tmux
    gh
  ]);
}
