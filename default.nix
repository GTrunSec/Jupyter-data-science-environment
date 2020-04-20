with import <nixpkgs> {};
let
  jupyter = import (builtins.fetchGit {
    url = https://github.com/tweag/jupyterWith;
    rev = "";
  }) {};

  iPython = jupyter.kernels.iPythonWith {
    name = "test";
    packages = p: with p; [ numpy pandas ];
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
