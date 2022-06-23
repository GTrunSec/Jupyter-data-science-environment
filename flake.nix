{
  description = "Data Science Environment";
  nixConfig = {
    flake-registry = "https://github.com/hardenedlinux/flake-registry/raw/main/flake-registry.json";
  };
  inputs = {
    utils.url = "/home/gtrun/ghq/github.com/gytis-ivaskevicius/flake-utils-plus";

    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    release.url = "github:NixOS/nixpkgs/release-22.05";

    mach-nix.inputs.nixpkgs.follows = "nixpkgs-unstable";
    mach-nix.inputs.pypi-deps-db.follows = "pypi-deps-db";

    flake-compat.flake = false;

    pypi-deps-db.url = "github:DavHau/pypi-deps-db";
    pypi-deps-db.flake = false;

    # url = "/home/gtrun/ghq/github.com/GTrunSec/jupyterWith/";
    jupyterWith.url = "github:tweag/jupyterWith";
    jupyterWith.inputs.nixpkgs.follows = "nixpkgs-unstable";

    #haskTorch = { url = "github:hasktorch/hasktorch"; };
  };

  outputs = inputs @ {
    self,
    nixpkgs-unstable,
    latest,
    mach-nix,
    pypi-deps-db,
    utils,
    flake-compat,
    devshell,
    jupyterWith,
    ...
  }: let
    inherit (utils.lib) exportOverlays exportPackages exportModules;
  in
    utils.lib.mkFlake
    {
      inherit self inputs;

      supportedSystems = ["x86_64-linux" "x86_64-darwin"];

      channelsConfig = {
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
          overlaysBuilder = channels: [];
        };
        release = {
          input = inputs.release;
          overlaysBuilder = channels: [];
        };
      };

      sharedOverlays =
        [
          self.overlays.default
          (final: prev: {
            __dontExport = true;
            mach-nix = inputs.mach-nix.lib."${prev.stdenv.hostPlatform.system}";
          })
        ]
        ++ (nixpkgs-unstable.lib.attrValues jupyterWith.overlays);

      overlays = exportOverlays {
        inherit (self) pkgs inputs;
      };

      outputsBuilder = channels: {
        packages = exportPackages self.overlays channels;
        devShells.default = import ./shell {inherit inputs channels;};
      };
    }
    // {
      overlays.default = final: prev: {
        jupyterlab-env = prev.callPackage ./nix/jupyterlab-env.nix {};
        jupyterlab-ci = prev.callPackage ./nix/jupyterlab-ci.nix {};
      };
    };
}
