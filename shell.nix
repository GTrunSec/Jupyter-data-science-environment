{ pkgs ? import <nixpkgs> {}
, nixpkgs-hardenedlinux
}:

with pkgs;
let
  voila = pkgs.writeScriptBin "voila" ''
    nix-shell ${nixpkgs-hardenedlinux}/pkgs/python/env/voila --command "voila"
  '';
in
mkShell {
  buildInputs = [
    voila
  ];
}
