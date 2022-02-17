{
  description = "Data Science Environment";
  nixConfig = {
    flake-registry = "https://github.com/hardenedlinux/flake-registry/raw/main/flake-registry.json";
  };
  inputs = {
    mach-nix = {
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.pypi-deps-db.follows = "pypi-deps-db";
    };
    flake-compat.flake = false;
    pypi-deps-db = {
      url = "github:DavHau/pypi-deps-db";
      flake = false;
    };
    jupyterWith = {
      #url = "/home/gtrun/ghq/github.com/GTrunSec/jupyterWith";
      url = "github:tweag/jupyterWith";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    funflowSrc = {
      url = "github:tweag/funflow";
      flake = false;
    };
    #haskTorch = { url = "github:hasktorch/hasktorch"; };
  };

  outputs =
    inputs @
    {
      self,
      nixpkgs-unstable,
      latest,
      mach-nix,
      pypi-deps-db,
      utils,
      flake-compat,
      devshell,
      jupyterWith,
      funflowSrc,
    }:
    let
      inherit (utils.lib) exportOverlays exportPackages exportModules;
    in
      utils.lib.mkFlake
      {
        inherit self inputs;

        supportedSystems = ["x86_64-linux" "x86_64-darwin"];

        channelsConfig = {
          allowUnsupportedSystem = true;
          allowBroken = true;
          allowUnfree = true;
        };
        channels = {
          nixpkgs = {
            input = nixpkgs-unstable;
            overlaysBuilder = channels: [
              devshell.overlay
              (import ./nix/overlays/override.nix channels)
            ];
          };
          latest = {
            input = latest;
            overlaysBuilder = channels: [
            ];
          };
        };

        sharedOverlays =
          [
            self.overlay
            (final: prev: {
              __dontExport = true;
              mach-nix = inputs.mach-nix.lib."${prev.stdenv.hostPlatform.system}";
              haskellPackages = prev.haskellPackages.override
              (old: {
                overrides = prev.lib.composeExtensions (old.overrides or (_: _: {})) (hfinal: hprev: {
                  funflow = prev.haskell.lib.overrideCabal
                  (hprev.callCabal2nix "funflow" "${inputs.funflowSrc}/funflow" {});
                  docker-client = prev.haskell.lib.overrideCabal
                  (hprev.callCabal2nix "docker-client" "${inputs.funflowSrc}/docker-client" {});
                });
              });
            })
          ]
          ++ (nixpkgs-unstable.lib.attrValues jupyterWith.overlays);

        overlays = exportOverlays {
          inherit (self) pkgs inputs;
        };

        outputsBuilder = channels: {
          packages = exportPackages self.overlays channels;
          devShell = import ./shell { inherit inputs channels; };
        };
      }
      // {
        overlay = final: prev: {
          jupyterlab-env = prev.callPackage ./nix/jupyterlab-env.nix {};
          jupyterlab-ci = prev.callPackage ./nix/jupyterlab-ci.nix {};
        };
      };
}
