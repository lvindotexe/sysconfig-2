{
  description = "Home Manager configuration of alvinv";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nvf, ... }:
    let
      mkHome = { system }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [
            ./home.nix
            nvf.homeManagerModules.default
          ];
        };
    in
    {
      homeConfigurations = {
        darwin = mkHome {
          system = "aarch64-darwin";
        };

        linux = mkHome {
          system = "x86_64-linux";
        };
      };
    };
}
