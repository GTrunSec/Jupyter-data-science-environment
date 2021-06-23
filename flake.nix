{
  description = "Data Science Environment";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/3a7674c896847d18e598fa5da23d7426cb9be3d2";
    stable.url = "nixpkgs/703f052de185c3dd1218165e62b105a68e05e15";
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
    devshell.url = "github:numtide/devshell";
    mach-nix = { url = "github:DavHau/mach-nix"; inputs.nixpkgs.follows = "nixpkgs"; inputs.pypi-deps-db.follows = "pypi-deps-db"; };
    pypi-deps-db = {
      url = "github:DavHau/pypi-deps-db";
      flake = false;
    };
    haskTorch = { url = "github:hasktorch/hasktorch/5f905f7ac62913a09cbb214d17c94dbc64fc8c7b"; flake = false; };
    jupyterWith = { url = "github:GTrunSec/jupyterWith/Mar"; flake = false; };
    haskell-nix = { url = "github:input-output-hk/haskell.nix"; flake = false; };
    #jupyterWith = { url = "/home/gtrun/data/jupyterWith"; flake = false; };
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , flake-compat
    , pypi-deps-db
    , flake-utils
    , jupyterWith
    , haskTorch
    , haskell-nix
    , stable
    , devshell
    , mach-nix
    }:
    (flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ]
      (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            self.overlay
            (import ./nix/overlays/python-overlay.nix)
            (import ./nix/overlays/package-overlay.nix)
            (import ./nix/overlays/haskell-overlay.nix)
          ];
          config = {
            allowBroken = true;
            allowUnfree = true;
            allowUnsupportedSystem = true;
          };
        };
      in
      rec {
        devShell = import ./devshell.nix { inherit pkgs; };
      }
      )
    ) // {
      overlay = final: prev: {
        jupyter = import jupyterWith { pkgs = final; };
        machlib = import mach-nix
          {
            pypiDataRev = pypi-deps-db.rev;
            pypiDataSha256 = pypi-deps-db.narHash;
            python = "python38";
            pkgs = prev;
          };
      };
    };
}
