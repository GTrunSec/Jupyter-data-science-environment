{ pkgs }:
with pkgs;
let
  python-custom = pkgs.machlib.mkPython rec {
    requirements = ''
      numpy
      pandas
    '';
  };

  iPython = jupyterWith.kernels.iPythonWith {
    name = "Python-data-env";
    python3 = python-custom.python;
    packages = python-custom.python.pkgs.selectPkgs;
    ignoreCollisions = true;
  };


  iHaskell = jupyterWith.kernels.iHaskellWith {
    extraIHaskellFlags = "--codemirror Haskell"; # for jupyterlab syntax highlighting
    name = "ihaskell-flake";
  };

  iJulia =
    let
      currentDir = builtins.getEnv "DEVSHELL_ROOT";
    in
    jupyterWith.kernels.iJuliaWith rec {
      name = "Julia-data-env";
      #Project.toml directory
      activateDir = currentDir + "/packages/julia";
      # JuliaPackages directory
      JULIA_DEPOT_PATH = activateDir + "/julia_depot";
      extraEnv = { };
    };


  iNix = jupyterWith.kernels.iNixKernel {
    name = "nix-kernel";
    nix = pkgs.nixFlakes;
  };

  jupyterEnvironment =
    jupyterWith.jupyterlabWith {
      kernels = [ iPython iHaskell iJulia iNix ];
      directory = "./.jupyterlab-ci";
    };
in
pkgs.mkShell rec {
  buildInputs = [
    jupyterEnvironment
    iJulia.runtimePackages
    iPython.runtimePackages
  ];

  JULIA_DEPOT_PATH = builtins.getEnv "DEVSHELL_ROOT" + "/packages/julia/julia_depot";
  shellHook = ''
    if [ ! -d "$DEVSHELL_ROOT/.jupyterlab-ci" ]; then
       jupyter lab build
    else
      rm -rf  $DEVSHELL_ROOT/.jupyterlab-ci
      jupyter lab build
    fi
  '';
}
