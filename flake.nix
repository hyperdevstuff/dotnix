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
    };
}
