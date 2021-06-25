{ pkgs }:
with pkgs;
let
  iPython = jupyter.kernels.iPythonWith {
    name = "Python-data-env";
    ignoreCollisions = true;
  };


  iHaskell = jupyter.kernels.iHaskellWith {
    extraIHaskellFlags = "--codemirror Haskell"; # for jupyterlab syntax highlighting
    name = "ihaskell-flake";
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
