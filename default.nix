let
   jupyterLib = builtins.fetchGit {
    url = https://github.com/tweag/jupyterWith;
    rev = "70f1dddd6446ab0155a5b0ff659153b397419a2d";
  };

   haskTorchSrc = builtins.fetchGit {
     url = https://github.com/hasktorch/hasktorch;
     rev = "7e017756fd9861218bf2f804d1f7eaa4d618eb01";
     ref = "master";
   };

   hasktorchOverlay = (import (haskTorchSrc + "/nix/shared.nix") { compiler = "ghc865"; }).overlayShared;
   haskellOverlay = import ./overlay/haskell-overlay.nix;

   overlays = [
    # Only necessary for Haskell kernel
     (import ./overlay/python.nix)
     haskellOverlay
     hasktorchOverlay
  ];

  pkgs = import <nixpkgs> { inherit overlays; };

  jupyter = import jupyterLib {pkgs=pkgs;};

  iPython = jupyter.kernels.iPythonWith {
    python3 = pkgs.callPackage ./overlay/own-python.nix {};
    name = "agriculture";
    packages = p: with p; [ numpy pandas matplotlib editdistance ipywidgets ];
  };

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "haskell";
    haskellPackages = pkgs.haskell.packages.ghc865;
    packages = p: with p; [ hvega
                            formatting
                            libtorch-ffi_cpu
                            inline-c
                            inline-c-cpp
                            hasktorch-examples_cpu
                            hasktorch_cpu
                            matrix
                            hmatrix
                            monad-bayes
                            hvega
                            statistics
                            vector
                            ihaskell-hvega
                            aeson
                            aeson-pretty
                            formatting
                            foldl
                            histogram-fill
                            funflow
                            JuicyPixels
                          ] ;
  };


  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython ];
       directory = jupyter.mkDirectoryWith {
         extensions = [
           "@jupyter-widgets/jupyterlab-manager@2.0"
        ];
       };
    };
in
  pkgs.mkShell rec {
  name = "analysis-arg";
  buildInputs = [ jupyterEnvironment
                  pkgs.python3Packages.ipywidgets
                ];
  shellHook = ''
  jupyter nbextension install --py widgetsnbextension --user
  jupyter nbextension enable --py widgetsnbextension
    '';
  }
