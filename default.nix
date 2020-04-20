with import <nixpkgs> {};
let
  jupyter = import (builtins.fetchGit {
    url = https://github.com/tweag/jupyterWith;
    rev = "7a6716f0c0a5538691a2f71a9f12b066bce7d55c";
  }) {};

  iPython = jupyter.kernels.iPythonWith {
    name = "agriculture";
    packages = p: with p; [ numpy pandas matplotlib];
  };

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "haskell";
    packages = p: with p; [ hvega formatting ];
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython ];
    };
in
#jupyterEnvironment.env
  mkShell rec {
  name = "analysis-arg";
  buildInputs = [jupyterEnvironment ];
  shellHook = ''
    jupyter-lab
  '';
  }
