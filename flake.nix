{
  description = "Data Science Environment";

  inputs = {
    utils.url = "github:gytis-ivaskevicius/flake-utils-plus/staging";
    nixpkgs.url = "nixpkgs/release-21.05";
    latest.url = "nixpkgs/nixos-unstable";
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
    devshell = { url = "github:numtide/devshell"; flake = false; };
    mach-nix = { url = "github:DavHau/mach-nix"; inputs.nixpkgs.follows = "nixpkgs"; inputs.pypi-deps-db.follows = "pypi-deps-db"; };
    pypi-deps-db = {
      url = "github:DavHau/pypi-deps-db";
      flake = false;
    };
    jupyterWith = { url = "github:GTrunSec/jupyterWith/main"; };
    #jupyterWith = { url = "/home/gtrun/ghq/github.com/GTrunSec/jupyterWith"; };
    haskTorch = { url = "github:hasktorch/hasktorch/5f905f7ac62913a09cbb214d17c94dbc64fc8c7b"; flake = false; };
    haskell-nix = { url = "github:input-output-hk/haskell.nix"; flake = false; };
  };

  outputs = inputs: with builtins; with inputs;
    let
      inherit (utils.lib.exporters) internalOverlays fromOverlays modulesFromList;
    in
    utils.lib.systemFlake
      {
        inherit self inputs;

        supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];

        channelsConfig = {
          allowUnsupportedSystem = true;
          allowBroken = true;
          allowUnfree = true;
        };
        channels = {
          nixpkgs = {
            input = nixpkgs;
            overlaysBuilder = channels:
              [
                (import "${devshell}/overlay.nix")
                (import ./nix/overlays/override.nix channels)
              ];
          };
          latest = {
            input = latest;
            overlaysBuilder = channels: [ ];
          };
        };

        sharedOverlays = [
          self.overlay
          (final: prev:
            {
              __dontExport = true;
              #python
              machlib = import mach-nix {
                pkgs = final;
                pypiData = pypi-deps-db;
              };
            })
        ] ++ (nixpkgs.lib.attrValues jupyterWith.overlays);

        overlays = internalOverlays {
          inherit (self) pkgs inputs;
        };

        outputsBuilder = channels: {
          # construct packagesBuilder to export all packages defined in overlays
          packages = fromOverlays self.overlays channels;
          devShell = with channels.nixpkgs; devshell.mkShell {
            name = "devShell";
            imports = [ (devshell.importTOML ./devshell.toml) ];
            commands = [ ];
          };
        };

      } // {
      overlay = final: prev: {
        jupyterWith-env = prev.callPackage ./nix/jupyterwith-env.nix { };
        jupyterWith-ci = prev.callPackage ./nix/jupyterwith-ci.nix { };
      };
    };
}
