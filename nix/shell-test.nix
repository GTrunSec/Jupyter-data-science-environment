{ pkgs ? import <nixpkgs> { }
, nixpkgs-hardenedlinux
, jupyterWith
, mach-nix
, stable
}:
let
  jupyter = import jupyterWith { inherit pkgs; };
  env = (import (jupyterWith + "/lib/directory.nix")) { inherit pkgs; };

  iPython = jupyter.kernels.iPythonWith {
    name = "Python-data-env";
    ignoreCollisions = true;
  };


  iHaskell = jupyter.kernels.iHaskellWith {
    extraIHaskellFlags = "--codemirror Haskell"; # for jupyterlab syntax highlighting
    name = "ihaskell-flake";
  };

  iRust = jupyter.kernels.rustWith {
    name = "data-rust-env";
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell ];
    };

in
pkgs.mkShell rec {
  buildInputs = [
    jupyterEnvironment
  ];
}
