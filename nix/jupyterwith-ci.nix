{ pkgs }:
with pkgs;
let
  python-custom = pkgs.machlib.mkPython rec {
    python = "python38";
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

  juliaPackages = builtins.getEnv "DEVSHELL_ROOT" + "/packages/julia/default";
  iJulia = jupyterWith.kernels.iJuliaWith rec {
    name = "Julia-data-env";
    #Project.toml directory
    activateDir = juliaPackages;
    # JuliaPackages directory
    JULIA_DEPOT_PATH = juliaPackages + "/julia_depot";
    extraEnv = { PYTHON = "${python-custom}/bin/python"; };
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

  JULIA_DEPOT_PATH = juliaPackages + "/julia_depot";

  shellHook = ''
    if [ ! -d "$DEVSHELL_ROOT/.jupyterlab-ci" ]; then
       jupyter lab build
    else
      rm -rf  $DEVSHELL_ROOT/.jupyterlab-ci
      jupyter lab build
    fi
  '';
}
