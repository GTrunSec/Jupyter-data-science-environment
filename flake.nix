{
  description = "hardenedlinux nixpkgs collection";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/4c67f879f0ee0f4eb610373e479a0a9c518c51c4";
    nixpkgs-hardenedlinux = { url = "github:hardenedlinux/nixpkgs-hardenedlinux/master"; flake = false; };
    haskTorch = { url = "github:hasktorch/hasktorch/5f905f7ac62913a09cbb214d17c94dbc64fc8c7b"; flake = false; };
    jupyterWith = { url = "github:GTrunSec/jupyterWith/Nov"; flake = false; };
    #jupyterWith = { url = "/home/gtrun/data/jupyterWith"; flake = false; };
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
            #ihaskell-0.10.1.1
            config = { allowBroken = true; sandbox = false; };
          };
        in
          {
            devShell = import ./shell.nix { inherit pkgs nixpkgs-hardenedlinux jupyterWith;};
          }
      )
    );
}
