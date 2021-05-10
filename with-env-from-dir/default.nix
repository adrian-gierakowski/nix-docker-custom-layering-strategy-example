{
  pkgs ? import ./../nixpkgs.nix {}
}:
  pkgs.callPackage (import ./package.nix) {}
