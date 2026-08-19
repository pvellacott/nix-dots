
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

      mkHost = hostname:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/${hostname}
            ./modules/home.nix
            home-manager.nixosModules.home-manager
          ];
        };
    in {
    nixosConfigurations.braptop = mkHost "braptop";

    nixosConfigurations.desktop = mkHost "desktop";
  };
}
