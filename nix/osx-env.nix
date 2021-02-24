let
  jupyterLib = builtins.fetchGit {
    url = https://github.com/GTrunSec/jupyterWith;
    rev = "d9fe46bce29dcdb026807335f46cb2b8655dbf6b";
    ref = "current";
  };

  haskTorchSrc = builtins.fetchGit {
    url = https://github.com/hasktorch/hasktorch;
    rev = "5f905f7ac62913a09cbb214d17c94dbc64fc8c7b";
    ref = "master";
  };

  hasktorchOverlay = (import (haskTorchSrc + "/nix/shared.nix") { compiler = "ghc883"; }).overlayShared;
  haskellOverlay = import ../overlay/haskell-overlay.nix;
  overlays = [
    # Only necessary for Haskell kernel
    (import ../overlay/python-overlay.nix)
    (import ../overlay/package-overlay.nix)
    (import ../overlay/julia.nix)
    haskellOverlay
    hasktorchOverlay
  ];


  pkgs = (import ./nixpkgs.nix) { inherit overlays; config = { allowUnfree = true; allowBroken = true; }; };

  jupyter = import jupyterLib { pkgs = pkgs; };


  iPython = jupyter.kernels.iPythonWith {
    python3 = pkgs.callPackage ../overlay/python-self-packages.nix { };
    name = "Python-data-env";
    packages = import ../overlay/osx-python-packages-list.nix { inherit pkgs; };
  };

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "ihaskell-data-env";
    haskellPackages = pkgs.haskell.packages.ghc883;
    packages = p: with p; [
      hvega
      #inline-r
      formatting
      inline-c
      inline-c-cpp
      #hasktorch_cpu
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

      diagrams
      ihaskell-diagrams
      ihaskell-blaze
      ihaskell-charts
      SVGFonts
      palette
      blaze
      Chart
      MissingH
      Rasterific
    ];
  };


  iRust = jupyter.kernels.rustWith {
    name = "data-rust-env";
  };

  IRkernel = jupyter.kernels.iRWith {
    name = "IRkernel-data-env";
    packages = import ../overlay/R-packages-list.nix { inherit pkgs; };
  };

  ihaskell_labextension = import ./ihaskell_labextension.nix { inherit jupyter pkgs; };
  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell iRust ];
      directory = jupyter.mkDirectoryWith {
        extensions = [
          ihaskell_labextension
          "@jupyter-widgets/jupyterlab-manager@2.0"
          "@bokeh/jupyter_bokeh@2.0.0"
          #"@jupyterlab/git@0.21.0-alpha.0"
          #"@krassowski/jupyterlab-lsp@1.1.2"
        ];
      };
    };

in
pkgs.mkShell rec {
  name = "analysis-arg";
  buildInputs = [
    jupyterEnvironment
    pkgs.python3Packages.ipywidgets
  ];
  shellHook = ''
     ${pkgs.python3Packages.jupyter_core}/bin/jupyter nbextension install --py widgetsnbextension --user
     ${pkgs.python3Packages.jupyter_core}/bin/jupyter nbextension enable --py widgetsnbextension
    #for emacs-ein to load kernels environment.
      ln -sfT ${iPython.spec}/kernels/ipython_Python-data-env ~/Library/Jupyter/kernels/ipython_Python-data-env
      ln -sfT ${iHaskell.spec}/kernels/ihaskell_ihaskell-data-env ~/Library/Jupyter/kernels/iHaskell-data-env
      ln -sfT ${iRust.spec}/kernels/rust_data-rust-env  ~/Library/Jupyter/kernels/IRust-data-env
  '';
}
