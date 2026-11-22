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
      url = "github:anomalyco/hex";
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
    in
    {
      nixosConfigurations.LOQ = nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs username;
        };

        modules = [
          ./hosts/LOQ

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";

            home-manager.extraSpecialArgs = {
              inherit inputs username;
            };

            home-manager.users.${username} = import ./home;
          }

        ];
      };

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
