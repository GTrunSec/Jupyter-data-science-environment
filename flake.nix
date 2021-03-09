{
  description = "Data Science Environment";
  # nixConfig = {
  #   substituters = [
  #     "http://221.4.35.244:8301/"
  #   ];
  #   trusted-public-keys = [
  #     "221.4.35.244:3ehdeUIC5gWzY+I7iF3lrpmxOMyEZQbZlcjOmlOVpeo="
  #   ];
  # };

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/703f052de185c3dd1218165e62b105a68e05e15f";
    julia_15.url = "nixpkgs/7d71001b796340b219d1bfa8552c81995017544a";
    python37.url = "nixpkgs/4c67f879f0ee0f4eb610373e479a0a9c518c51c4"; #python3.7 tensorflow_2
    devshell.url = "github:numtide/devshell";
    nixpkgs-hardenedlinux = { url = "github:hardenedlinux/nixpkgs-hardenedlinux/master"; flake = false; };
    haskTorch = { url = "github:hasktorch/hasktorch/5f905f7ac62913a09cbb214d17c94dbc64fc8c7b"; flake = false; };
    jupyterWith = { url = "github:GTrunSec/jupyterWith/Nov"; flake = false; };
    haskell-nix = { url = "github:input-output-hk/haskell.nix"; flake = false; };
    #jupyterWith = { url = "/home/gtrun/data/jupyterWith"; flake = false; };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, nixpkgs-hardenedlinux, jupyterWith, haskTorch, haskell-nix, python37, julia_15, devshell }:
    (flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [
              (import ./nix/overlays/python-overlay.nix)
              (import ./nix/overlays/package-overlay.nix)
              (import ./nix/overlays/julia-overlay.nix)
              (import ./nix/overlays/haskell-overlay.nix)
              (import (nixpkgs-hardenedlinux + "/nix/python-packages-overlay.nix"))
            ];
            config = {
              allowBroken = true;
              allowUnfree = true;
              allowUnsupportedSystem = true;
            };
          };
        in
        {
          devShell = import ./shell.nix { inherit pkgs nixpkgs-hardenedlinux jupyterWith; };
        }
      )
    );
}
