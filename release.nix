let
  jupyterLib = import <jupyterLib>;

  haskTorchSrc = import <haskTorchSrc>;

  hasktorchOverlay = (import <haskTorchSrc/nix/shared.nix> { compiler = "ghc865"; }).overlayShared;
  haskellOverlay = import ./overlay/haskell-overlay.nix;
  ROverlay = import ./overlay/R-overlay.nix;
  overlays = [
    # Only necessary for Haskell kernel
    (import ./overlay/python.nix)
    haskellOverlay
    hasktorchOverlay
    ROverlay
  ];

  pkgs = import <jupyterLib-nix> { inherit overlays; config={ allowUnfree=true; allowBroken=true;};};

  jupyter = import <jupyterLib> {pkgs=pkgs;};
  
  ihaskell_labextension = pkgs.fetchurl {
    url = "https://github.com/GTrunSec/ihaskell_labextension/releases/download/fetchurl/package.tar.gz";
    sha256 = "0i17yd3b9cgfkjxmv9rdv3s31aip6hxph5x70s04l9xidlvsp603";
  };

  iPython = jupyter.kernels.iPythonWith {
    python3 = pkgs.callPackage ./overlay/own-python.nix {};
    name = "agriculture";
    packages = p: with p; [ numpy pandas matplotlib editdistance ipywidgets ];
  };

  IRkernel = jupyter.kernels.iRWith {
    name = "IRkernel";
    packages = p: with p; [ devtools ];
  };

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "haskell";
    haskellPackages = pkgs.haskell.packages.ghc865;
    packages = p: with p; [ hvega
                            formatting
                            inline-r
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
      kernels = [ iPython iHaskell IRkernel ];
      directory = jupyter.mkDirectoryWith {
        extensions = [
          "@jupyter-widgets/jupyterlab-manager@2.0"
          #"${ihaskell_labextension}" does not work
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
