{ pkgs ? import <nixpkgs> { }
, nixpkgs-hardenedlinux
, jupyterWith
}:
let
  jupyter = import jupyterWith { inherit pkgs; };
  env = (import (jupyterWith + "/lib/directory.nix")) { inherit pkgs Rpackages; };
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
    packages = import ./nix/overlays/python-packages-list.nix {
      inherit pkgs;
      MachineLearning = true;
      DataScience = true;
      Financial = true;
      Graph = true;
      SecurityAnalysis = true;
    };
    ignoreCollisions = true;
  };


  iHaskell = jupyter.kernels.iHaskellWith {
    extraIHaskellFlags = "--codemirror Haskell"; # for jupyterlab syntax highlighting
    name = "ihaskell-flake";
    packages = import ./nix/overlays/haskell-packages-list.nix {
      inherit pkgs;
      Diagrams = true;
      Hasktorch = true;
      InlineC = false;
      Matrix = true;
    };
    r-libs-site = env.r-libs-site;
    r-bin-path = env.r-bin-path;
  };


  IRkernel = jupyter.kernels.iRWith {
    name = "IRkernel-data-env";
    packages = import ./nix/overlays/R-packages-list.nix { inherit pkgs; };
  };

  iRust = jupyter.kernels.rustWith {
    name = "data-rust-env";
  };

  julia_wrapped = import ./nix/julia2nix-env { };
  currentDir = builtins.getEnv "PWD";
  iJulia = jupyter.kernels.iJuliaWith {
    name = "Julia-data-env";
    inherit julia_wrapped;
    directory = julia_wrapped.depot;
    activateDir = currentDir + "/nix/julia2nix-env";
  };


  iNix = jupyter.kernels.iNixKernel {
    name = "nix-kernel";
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell IRkernel iJulia iNix iRust ];
      extraPackages = p: with p;[ python3Packages.jupytext ];
      extraJupyterPath = p: "${p.python3Packages.jupytext}/${p.python3.sitePackages}";
    };
in
pkgs.mkShell rec {
  buildInputs = [
    #voila
    jupyterEnvironment
    iJulia.runtimePackages
    iPython.runtimePackages
  ];
  shellHook = ''
      ln -sfT ${iPython.spec}/kernels/ipython_Python-data-env ~/.local/share/jupyter/kernels/ipython_Python-data-env
      ln -sfT ${iHaskell.spec}/kernels/ihaskell_ihaskell-data-env ~/.local/share/jupyter/kernels/iHaskell-data-env
      ln -sfT ${iJulia.spec}/kernels/julia_Julia-data-env ~/.local/share/jupyter/kernels/iJulia-data-env
      ln -sfT ${IRkernel.spec}/kernels/ir_IRkernel-data-env ~/.local/share/jupyter/kernels/IRkernel-data-env
      ln -sfT ${iNix.spec}/kernels/inix_nix-kernel/  ~/.local/share/jupyter/kernels/INix-data-env
      ln -sfT ${iRust.spec}/kernels/rust_data-rust-env  ~/.local/share/jupyter/kernels/IRust-data-env
    #${jupyterEnvironment}/bin/jupyter-lab
  '';
}
