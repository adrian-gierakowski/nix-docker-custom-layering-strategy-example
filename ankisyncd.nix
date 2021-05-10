{
  pkgs ? import ./nixpkgs.nix {}
}:
  pkgs.ankisyncd
