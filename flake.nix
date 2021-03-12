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
    nixpkgs.url = "nixpkgs/master";
    stable.url = "nixpkgs/703f052de185c3dd1218165e62b105a68e05e15";
    devshell.url = "github:numtide/devshell";
    mach-nix = { url = "github:DavHau/mach-nix"; inputs.nixpkgs.follows = "nixpkgs"; };
    nixpkgs-hardenedlinux = { url = "github:hardenedlinux/nixpkgs-hardenedlinux/master"; flake = false; };
    haskTorch = { url = "github:hasktorch/hasktorch/5f905f7ac62913a09cbb214d17c94dbc64fc8c7b"; flake = false; };
    jupyterWith = { url = "github:GTrunSec/jupyterWith/Nov"; flake = false; };
    haskell-nix = { url = "github:input-output-hk/haskell.nix"; flake = false; };
    #jupyterWith = { url = "/home/gtrun/data/jupyterWith"; flake = false; };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, nixpkgs-hardenedlinux, jupyterWith, haskTorch, haskell-nix, stable, devshell, mach-nix }:
    (flake-utils.lib.eachDefaultSystem
      (system:
        let
          machlib = import mach-nix
            {
              inherit system;
              pypiDataRev = "2205d5a0fc9b691e7190d18ba164a3c594570a4b";
              pypiDataSha256 = "1aaylax7jlwsphyz3p73790qbrmva3mzm56yf5pbd8hbkaavcp9g";
            };
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [
              (import ./nix/overlays/python-overlay.nix)
              (import ./nix/overlays/package-overlay.nix)
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
        rec {
          devShell = import ./shell.nix {
            inherit pkgs stable nixpkgs-hardenedlinux jupyterWith; mach-nix = machlib;
          };
        }
      )
    );
}
