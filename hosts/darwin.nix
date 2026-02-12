{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    colima
    cacert
  ];

  homebrew = {
    enable = true;

    casks = [
      "ghostty"
      "google-chrome"
      "obs"
    ];

    brews = [
      "tailscale"
    ];

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "zap";
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    ssl-cert-file = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  };

  system.stateVersion = 6;
}
