{ pkgs ? import <nixpkgs> { }
, nixpkgs-hardenedlinux
, jupyterWith
}:
let
  jupyter = import jupyterWith { inherit pkgs; };
  env = (import (jupyterWith + "/lib/directory.nix")) { inherit pkgs Rpackages; };

  Rpackages = p: with p; [ ];


  iPython = jupyter.kernels.iPythonWith {
    name = "Python-data-env";
    ignoreCollisions = true;
  };


  iHaskell = jupyter.kernels.iHaskellWith {
    extraIHaskellFlags = "--codemirror Haskell"; # for jupyterlab syntax highlighting
    name = "ihaskell-flake";
    r-libs-site = env.r-libs-site;
    r-bin-path = env.r-bin-path;
  };

  IRkernel = jupyter.kernels.iRWith {
    name = "IRkernel-data-env";
  };

  iRust = jupyter.kernels.rustWith {
    name = "data-rust-env";
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell IRkernel iRust ];
    };

  voila = pkgs.writeScriptBin "voila" ''
    nix-shell ${nixpkgs-hardenedlinux}/pkgs/python/env/voila --command "voila"
  '';
in
pkgs.mkShell rec {
  buildInputs = [
    voila
    jupyterEnvironment
  ];
}
