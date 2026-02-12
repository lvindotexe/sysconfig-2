{
  description = "Unified Nix configuration — nix-darwin + Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, nvf, ... }:
    let
      hmModules = [
        ./home.nix
        nvf.homeManagerModules.default
      ];

      local =
        if builtins.pathExists ./local.nix
        then import ./local.nix
        else null;

      mkDarwin = { system, username }:
        nix-darwin.lib.darwinSystem {
          inherit system;
          modules = [
            ./hosts/darwin.nix
            home-manager.darwinModules.home-manager
            {
              nixpkgs.hostPlatform = system;

              system.primaryUser = username;
              system.configurationRevision =
                self.rev or self.dirtyRev or null;

              users.users.${username}.home = "/Users/${username}";

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = {
                imports = hmModules;
                home.username = username;
                home.homeDirectory = "/Users/${username}";
              };
            }
          ];
        };

      mkNixOS = { system, username, extraModules ? [] }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/nixos.nix
            home-manager.nixosModules.home-manager
            {
              nixpkgs.hostPlatform = system;

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = {
                imports = hmModules;
                home.username = username;
                home.homeDirectory = "/home/${username}";
              };
            }
          ] ++ extraModules;
        };

      mkStandaloneHome = { system, username }:
        let
          isDarwin = builtins.match ".*-darwin" system != null;
          homeDirectory =
            if isDarwin then "/Users/${username}"
            else "/home/${username}";
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = hmModules ++ [
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
            }
          ];
        };
    in
    {
      darwinConfigurations =
        if local != null && local.platform == "darwin"
        then { ${local.hostname} = mkDarwin { inherit (local) system username; }; }
        else {};

      nixosConfigurations =
        if local != null && local.platform == "nixos"
        then { ${local.hostname} = mkNixOS { inherit (local) system username; }; }
        else {};

      homeConfigurations =
        if local != null && local.platform == "linux"
        then { ${local.username} = mkStandaloneHome { inherit (local) system username; }; }
        else {};

      homeManagerModules.default = {
        imports = hmModules;
      };
    };
}
