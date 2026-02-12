{ pkgs, lib, ... }:

let
  hasGhosttySupport = pkgs.stdenv.isDarwin || pkgs.stdenv.isLinux;
in
{
  programs.ghostty = lib.mkIf hasGhosttySupport (lib.mkMerge [
    {
      enable = true;
      settings.theme = "Catppuccin Mocha";
    }
    (lib.mkIf pkgs.stdenv.isDarwin {
      package = null;
      systemd.enable = false;
    })
  ]);
}
