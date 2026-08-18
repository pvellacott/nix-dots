
{
  description = "smoo NixOS config";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";

      mkHost = { hostname, areYaGaminSon }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit areYaGaminSon; };
          modules = [
            ./hosts/${hostname}
            ./modules/home.nix
            ./modules/steamstuff.nix
            home-manager.nixosModules.home-manager
          ];
        };
    in {
    nixosConfigurations.braptop = mkHost {
      hostname = "braptop";
      areYaGaminSon = false;
    };

    nixosConfigurations.desktop = mkHost {
      hostname = "desktop";
      areYaGaminSon = true;
    };
  };
}
