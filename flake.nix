{
  description = "Data Science Environment";

  inputs = {
    utils.url = "github:gytis-ivaskevicius/flake-utils-plus";
    nixpkgs.url = "github:NixOS/nixpkgs/release-21.11";
    latest.url = "github:NixOS/nixpkgs/master";
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
    devshell = { url = "github:numtide/devshell"; flake = false; };
    mach-nix = { url = "github:DavHau/mach-nix"; inputs.nixpkgs.follows = "nixpkgs"; inputs.pypi-deps-db.follows = "pypi-deps-db"; };
    pypi-deps-db = {
      url = "github:DavHau/pypi-deps-db";
      flake = false;
    };
    jupyterWith = { url = "github:tweag/jupyterWith"; };
    funflowSrc = { url = "github:tweag/funflow"; flake = false; };
    #jupyterWith = { url = "/home/gtrun/ghq/github.com/GTrunSec/jupyterWith"; };
    #haskTorch = { url = "github:hasktorch/hasktorch"; };
  };

  outputs = inputs: with builtins; with inputs;
    let
      inherit (utils.lib) exportOverlays exportPackages exportModules;
    in
    utils.lib.mkFlake
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
              haskellPackages = prev.haskellPackages.override
                (old: {
                  overrides = prev.lib.composeExtensions (old.overrides or (_: _: { })) (hfinal: hprev:
                    {
                      funflow = prev.haskell.lib.overrideCabal
                        (hprev.callCabal2nix "funflow" "${inputs.funflowSrc}/funflow" { });
                    });
                });
            })
        ] ++ (nixpkgs.lib.attrValues jupyterWith.overlays);

        overlays = exportOverlays {
          inherit (self) pkgs inputs;
        };

        outputsBuilder = channels: {
          # construct packagesBuilder to export all packages defined in overlays
          packages = exportPackages self.overlays channels;
          devShell = import ./shell { inherit self inputs channels; };
        };

      } // {
      overlay = final: prev: {
        jupyterlab-env = prev.callPackage ./nix/jupyterlab-env.nix { };
        jupyterlab-ci = prev.callPackage ./nix/jupyterlab-ci.nix { };
      };
    };
}
