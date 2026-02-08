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
      localConfig =
        if builtins.pathExists ./local.nix then
          import ./local.nix
        else
          { };

      defaultUsername =
        if localConfig ? defaults && localConfig.defaults ? username then
          localConfig.defaults.username
        else
          "user";

      profileOverrides =
        if localConfig ? profiles then
          localConfig.profiles
        else
          { };

      mkIdentity = { profileName, system }:
        let
          profileConfig =
            if builtins.hasAttr profileName profileOverrides then
              builtins.getAttr profileName profileOverrides
            else
              { };

          username =
            if profileConfig ? username then
              profileConfig.username
            else
              defaultUsername;

          homeDirectory =
            if profileConfig ? homeDirectory then
              profileConfig.homeDirectory
            else if builtins.match ".*-darwin" system != null then
              "/Users/${username}"
            else
              "/home/${username}";
        in
        {
          inherit username homeDirectory;
        };

      mkHome = { profileName, system }:
        let
          identity = mkIdentity {
            inherit profileName system;
          };
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [
            ./home.nix
            nvf.homeManagerModules.default
            {
              home.username = identity.username;
              home.homeDirectory = identity.homeDirectory;
            }
          ];
        };

      matrixHomeConfigurations = {
        darwin-aarch64 = mkHome {
          profileName = "darwin-aarch64";
          system = "aarch64-darwin";
        };

        darwin-x86_64 = mkHome {
          profileName = "darwin-x86_64";
          system = "x86_64-darwin";
        };

        linux-x86_64 = mkHome {
          profileName = "linux-x86_64";
          system = "x86_64-linux";
        };

        linux-aarch64 = mkHome {
          profileName = "linux-aarch64";
          system = "aarch64-linux";
        };
      };
    in
    {
      homeConfigurations = matrixHomeConfigurations // {
        # Backward-compatible aliases for existing bootstrap usage.
        darwin = matrixHomeConfigurations.darwin-aarch64;
        linux = matrixHomeConfigurations.linux-x86_64;
      };
    };
}
