let
  inherit (inputflake) loadInput flakeLock;
  inputflake = import ../nix/lib.nix { };
  pkgs = (import (loadInput flakeLock.nixpkgs)) { inherit overlays; config = { allowUnfree = true; allowBroken = true; }; };

  #jupyter = (import (loadInput flakeLock.jupyterWith)) { inherit pkgs; };
  jupyter = (import ../../jupyterWith) { inherit pkgs; };
  env = (import ((loadInput flakeLock.jupyterWith) + "/lib/directory.nix")) { inherit pkgs Rpackages; };

  overlays = [
    # Only necessary for Haskell kernel
    (import ../nix/overlays/python-overlay.nix)
    (import ../nix/overlays/package-overlay.nix)
    (import ../nix/overlays/julia-overlay.nix)
    (import ../nix/overlays/haskell-overlay.nix)
    (import ((loadInput flakeLock.nixpkgs-hardenedlinux) + "/nix/python-packages-overlay.nix"))
  ];


  Rpackages = p: with p; [
    ggplot2
    dplyr
    xts
    purrr
    cmaes
    cubature
    reshape2
  ];

  iPython = jupyter.kernels.iPythonWith {
    name = "Python-data-env";
    packages = import ../nix/overlays/python-packages-list.nix {
      inherit pkgs;
      MachineLearning = true;
      DataScience = true;
      Financial = true;
      Graph = true;
      SecurityAnalysis = true;
    };
    ignoreCollisions = true;
  };

  IRkernel = jupyter.kernels.iRWith {
    name = "IRkernel-data-env";
    packages = import ../nix/overlays/R-packages-list.nix { inherit pkgs; };
  };

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "ihaskell-data-env";
    extraIHaskellFlags = "--codemirror Haskell"; # for jupyterlab syntax highlighting
    packages = import ../nix/overlays/haskell-packages-list.nix {
      inherit pkgs;
      Diagrams = true;
      Hasktorch = true;
      InlineC = false;
      Matrix = true;
    };
    r-libs-site = env.r-libs-site;
    r-bin-path = env.r-bin-path;
  };

  julia_wrapped = import ../nix/julia2nix { };
  iJulia = jupyter.kernels.iJuliaWith {
    name = "Julia-data-env";
    inherit julia_wrapped;
    directory = julia_wrapped.depot;
  };

  iNix = jupyter.kernels.iNixKernel {
    name = "nix-kernel";
  };


  iRust = jupyter.kernels.rustWith {
    name = "data-rust-env";
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [
        # iPython iHaskell IRkernel iJulia iNix
        iJulia
      ];
    };

in
pkgs.mkShell rec {
  name = "Jupyter-data-build-Env";
  buildInputs = [
    jupyterEnvironment
    iJulia.runtimePackages
    iJulia.spec
  ];
}
