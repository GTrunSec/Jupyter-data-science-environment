{
  description = "hardenedlinux nixpkgs collection";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/302ef60620d277fc87a8aa58c5c561b62c925651";
    nixpkgs-hardenedlinux.url = "github:hardenedlinux/nixpkgs-hardenedlinux/master";
    haskTorch = { url = "github:hasktorch/hasktorch/5f905f7ac62913a09cbb214d17c94dbc64fc8c7b"; flake = false; };
    jupyterWith = { url = "github:GTrunSec/jupyterWith/c1ccbe1b0ee5703fd425ce0a3442e7e2ecfde352"; flake = false; };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, nixpkgs-hardenedlinux, jupyterWith, haskTorch }:
    (flake-utils.lib.eachDefaultSystem
        (system:
          let
            hasktorchOverlay = (import (haskTorch + "/nix/shared.nix") { compiler = "ghc883"; }).overlayShared;
            pkgs = import nixpkgs {
              inherit system;
              overlays = [
                (import ./overlays/python-overlay.nix)
                (import ./overlays/package-overlay.nix)
                (import ./overlays/julia-overlay.nix)
                (import ./overlays/haskell-overlay.nix)
                hasktorchOverlay
              ];
            };
           in
            {
              devShell = import ./shell.nix { inherit pkgs nixpkgs-hardenedlinux jupyterWith;};
          }
        )
    );
  }
