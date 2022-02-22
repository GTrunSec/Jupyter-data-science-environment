{
  pkgs,
  julia_depot_path ? (builtins.getEnv "PRJ_ROOT" + "/packages/julia/JuliaTutorial"),
}: let
  python-custom = pkgs.mach-nix.mkPython rec {
    python = "python3";
    requirements = ''
      numpy
      pandas
    '';
  };

  iPython = pkgs.jupyterWith.kernels.iPythonWith {
    name = "Python-data-env";
    python3 = python-custom.python;
    packages = python-custom.python.pkgs.selectPkgs;
    ignoreCollisions = true;
  };

  iHaskell = pkgs.jupyterWith.kernels.iHaskellWith {
    extraIHaskellFlags = "--codemirror Haskell"; # for jupyterlab syntax highlighting
    name = "ihaskell-flake";
  };

  juliaPackages = builtins.getEnv "PRJ_ROOT" + "/packages/julia/default";
  iJulia = pkgs.jupyterWith.kernels.iJuliaWith rec {
    name = "Julia-data-env";
    #Project.toml directory
    activateDir = juliaPackages;
    # JuliaPackages directory
    JULIA_DEPOT_PATH = juliaPackages + "/julia_depot";
    extraEnv = {PYTHON = "${python-custom}/bin/python";};
  };

  iNix = pkgs.jupyterWith.kernels.iNixKernel {
    name = "nix-kernel";
    nix = pkgs.nixFlakes;
  };

  jupyterEnvironment =
    pkgs.jupyterWith.jupyterlabWith {
      kernels = [iPython iHaskell iJulia iNix];
      directory = "./jupyterlab";
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
    '';
  }
