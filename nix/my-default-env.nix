let
  inherit (inputflake) loadInput flakeLock;
  inputflake = import ../nix/lib.nix { };
  pkgs = (import (loadInput flakeLock.nixpkgs)) { inherit overlays; config = { allowUnfree = true; allowBroken = true; }; };

  #jupyter = (import (loadInput flakeLock.jupyterWith)) { inherit pkgs; };
  jupyter = (import ../../jupyterWith) { inherit pkgs; };
  env = (import ../../jupyterWith/lib/directory.nix) { inherit pkgs Rpackages; };

  overlays = [
    # Only necessary for Haskell kernel
    (import ../nix/overlays/python-overlay.nix)
    (import ../nix/overlays/package-overlay.nix)
    (import ../nix/overlays/haskell-overlay.nix)
  ];

  iPython = jupyter.kernels.iPythonWith {
    name = "
    Python-data-env ";
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

  Rpackages = p: with p; [
    ggplot2
    dplyr
  ];
  iHaskell = jupyter.kernels.iHaskellWith {
    name = "ihaskell-data-env";
    extraIHaskellFlags = "--codemirror Haskell "; # for jupyterlab syntax highlighting
    packages = import ../nix/overlays/haskell-packages-list.nix {
      inherit pkgs;
      Diagrams = false;
      Hasktorch = false;
      InlineR = false;
      Matrix = true;
    };
    extraEnv = ''
      export LD_LIBRARY_PATH=${pkgs.R}/lib/R/lib
      export R_LIBS_SITE=${builtins.readFile env.r-libs-site}
    '';
  };


  julia_wrapped = import ../nix/julia2nix-env { };
  currentDir = builtins.getEnv "PWD";
  iJulia = jupyter.kernels.iJuliaWith {
    name = "Julia-data-env";
    inherit julia_wrapped;
    directory = julia_wrapped.depot;
    activateDir = currentDir + "/julia2nix-env";
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
  shellHook = ''
    ln -sfT ${iHaskell.spec}/kernels/ihaskell_ihaskell-data-env ~/.local/share/jupyter/kernels/iHaskell-data-env
  '';
}
