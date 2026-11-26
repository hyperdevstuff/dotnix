{
  description = "dotnix - NixOS + Home Manager configuration for hyper";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium-browser = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hex = {
      # Keep the Home Manager module on the release packaged in pkgs/hex-bin.nix.
      url = "github:anomalyco/hex/v3.4.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      helium-browser,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      username = "hyper";

      mkHost =
        hostOutput: hostModule: desktopModule:
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit inputs username;
          };

          modules = [
            hostModule
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";

              home-manager.extraSpecialArgs = {
                inherit inputs username hostOutput;
              };

              home-manager.users.${username}.imports = [
                ./home
                desktopModule
              ];
            }
          ];
        };
    in
    {
      nixosConfigurations.LOQ = mkHost "LOQ" ./hosts/LOQ ./home/notchd.nix;
      nixosConfigurations.LOQ-dux = mkHost "LOQ-dux" ./hosts/LOQ-dux ./home/dux.nix;

      # Local packages, exposed so `nix build .#<name>` works. The same set is
      # importable as `nix build -f pkgs <name>`, which is also how
      # `nix-update -f pkgs <name>` updates them.
      packages.${system} =
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        import ./pkgs { inherit pkgs; };
    };
}
