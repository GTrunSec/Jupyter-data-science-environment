{ pkgs ? import <nixpkgs> {} }:

let

  jupyter = import (builtins.fetchGit {
    url = https://github.com/tweag/jupyterWith;
    rev = "7a6716f0c0a5538691a2f71a9f12b066bce7d55c";
  }) {};


  iPython = jupyter.kernels.iPythonWith {
    python3 = pkgs.callPackage ./python.nix {};
    name = "agriculture";
    packages = p: with p; [ numpy pandas matplotlib editdistance ];

  };

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "haskell";
    packages = p: with p; [ hvega formatting ] ;
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython ];
    };
in
  pkgs.mkShell rec {
  name = "analysis-arg";
  buildInputs = [jupyterEnvironment ];
  shellHook = ''
    jupyter-lab
  '';
  }
