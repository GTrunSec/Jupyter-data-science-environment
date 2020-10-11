{
  description = "hardenedlinux nixpkgs collection";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "nixpkgs/302ef60620d277fc87a8aa58c5c561b62c925651";
    nixpkgs-hardenedlinux.url = "github:hardenedlinux/nixpkgs-hardenedlinux/master";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, nixpkgs-hardenedlinux}:
    (flake-utils.lib.eachDefaultSystem
        (system:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [
              ];
            };
           in
            {
              devShell = import ./shell.nix { inherit pkgs nixpkgs-hardenedlinux;};
          }
        )
    );
  }
