 let
  jupyterLib = builtins.fetchGit {
    url = https://github.com/GTrunSec/jupyterWith;
    rev = "e57e567c31accc7b221da95e8395f3c5e57a3b94";
    ref = "current";
  };

  haskTorchSrc = builtins.fetchGit {
    url = https://github.com/hasktorch/hasktorch;
    rev = "5f905f7ac62913a09cbb214d17c94dbc64fc8c7b";
    ref = "master";
  };

  hasktorchOverlay = (import (haskTorchSrc + "/nix/shared.nix") { compiler = "ghc883"; }).overlayShared;
  haskellOverlay = import ./overlay/haskell-overlay.nix;
  overlays = [
    # Only necessary for Haskell kernel
    (import ./overlay/python-overlay.nix)
    (import ./overlay/package-overlay.nix)
    (import ./overlay/julia.nix)
    haskellOverlay
    hasktorchOverlay
  ];

  pkgs = (import ./nix/nixpkgs.nix) { inherit overlays; config={ allowUnfree=true; allowBroken=true; };};

  jupyter = import jupyterLib {pkgs=pkgs;};

  ihaskell_labextension = import ./nix/ihaskell_labextension.nix { inherit jupyter pkgs; };
  
  iPython = jupyter.kernels.iPythonWith {
    python3 = pkgs.callPackage ./overlay/python-self-packages.nix { inherit pkgs;};
    name = "Python-data-env";
    packages = import ./overlay/python-packages-list.nix {inherit pkgs;};
    ignoreCollisions = true;
  };

  IRkernel = jupyter.kernels.iRWith {
    name = "IRkernel-data-env";
    packages = import ./overlay/R-packages-list.nix {inherit pkgs;};
   };

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "ihaskell-data-env";
    haskellPackages = pkgs.haskell.packages.ghc883;
    packages = import ./overlay/haskell-packages-list.nix {inherit pkgs;};
    Rpackages = p: with p; [ ggplot2 dplyr xts purrr cmaes cubature
                             reshape2
                           ];
    inline-r = true;
  };

  ##julia part
  currentDir = builtins.getEnv "PWD";
  iJulia = jupyter.kernels.iJuliaWith {
    name =  "Julia-data-env";
    directory = currentDir + "/.julia_pkgs";
    ##julia_1.5.1
    NUM_THREADS = 12;
    extraPackages = p: with p;[   # GZip.jl # Required by DataFrames.jl
      gzip
      zlib
      libgit2
    ];
  };

  iNix = jupyter.kernels.iNixKernel {
    name = "nix-kernel";
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels= [ iPython iHaskell IRkernel iJulia iNix ];
      directory = jupyter.mkDirectoryWith {
        extensions = [
          ihaskell_labextension
          "@jupyter-widgets/jupyterlab-manager@2.0"
          "@bokeh/jupyter_bokeh@2.0.0"
          #"@jupyterlab/git@0.21.0-alpha.0"
          "@krassowski/jupyterlab-lsp@1.1.2"
        ];
      };
      extraPackages = p: with p;[ python3Packages.jupyter_lsp python3Packages.python-language-server ];
      extraJupyterPath = p: "${p.python3Packages.jupyter_lsp}/lib/python3.7/site-packages:${p.python3Packages.python-language-server}/lib/python3.7/site-packages";
    };

 in
   pkgs.mkShell rec {
     name = "Jupyter-data-Env";
     buildInputs = [ jupyterEnvironment
                     pkgs.python3Packages.ipywidgets
                     pkgs.python3Packages.python-language-server
                     pkgs.python3Packages.jupyter_lsp
                     Julia.runtimePackages
                   ];

     shellHook = ''
     ${pkgs.python3Packages.jupyter_core}/bin/jupyter nbextension install --py widgetsnbextension --user
     ${pkgs.python3Packages.jupyter_core}/bin/jupyter nbextension enable --py widgetsnbextension
    #${jupyterEnvironment}/bin/jupyter-lab --ip
    '';
   }
