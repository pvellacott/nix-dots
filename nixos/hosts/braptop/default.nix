{ lib, ... }:

{
  imports = [
    ../../configuration.nix
  ] ++ lib.optionals (builtins.pathExists ../../hardware-configuration.nix) [
    ../../hardware-configuration.nix
  ];

  networking.hostName = "braptop";
}
