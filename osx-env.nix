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
   nixpkgsPath = jupyterLib + "/nix";

  pkgs = import nixpkgsPath { inherit overlays; config={ allowUnfree=true; allowBroken=true;};};

  jupyter = import jupyterLib {pkgs=pkgs;};

  ihaskell_labextension = pkgs.fetchurl {
    url = "https://github.com/GTrunSec/ihaskell_labextension/releases/download/fetchurl/package.tar.gz";
    sha256 = "0i17yd3b9cgfkjxmv9rdv3s31aip6hxph5x70s04l9xidlvsp603";
  };

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
                            #funflow osx failed
                            JuicyPixels
                          ] ;
  };


  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell ];
       directory = jupyter.mkDirectoryWith {
         extensions = [
           "@jupyter-widgets/jupyterlab-manager@2.0"
           #"jupyterlab-ihaskell@0.0.7" https://github.com/gibiansky/IHaskell/pull/1151
           "${ihaskell_labextension}"
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
  jupyter nbextension enable --py widgetsnbextension
  jupyter-lab
    '';
  }
