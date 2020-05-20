let
  jupyterLib = builtins.fetchGit {
    url = https://github.com/GTrunSec/jupyterWith;
    rev = "8df01f073116b8b88c7a2d659c075401e187121b";
    ref = "current";
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

  
  env = (import (jupyterLib + "/lib/directory.nix")){ inherit pkgs;};
  
  pkgs = import nixpkgsPath { inherit overlays; config={ allowUnfree=true; allowBroken=true; ignoreCollisions = true;};};

  jupyter = import jupyterLib {pkgs=pkgs;};
  
  ihaskell_labextension = pkgs.fetchurl {
    url = "https://github.com/GTrunSec/ihaskell_labextension/releases/download/fetchurl/package.tar.gz";
    sha256 = "0i17yd3b9cgfkjxmv9rdv3s31aip6hxph5x70s04l9xidlvsp603";
  };

  iPython = jupyter.kernels.iPythonWith {
    python3 = pkgs.callPackage ./overlay/own-python.nix { inherit pkgs;};
    name = "Python-data-Env";
    packages = import ./overlay/python-list.nix {inherit pkgs;};
    ignoreCollisions = true;
  };

  IRkernel = jupyter.kernels.iRWith {
    name = "IRkernel-data-env";
    packages = import ./overlay/R-list.nix {inherit pkgs;};
   };

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "ihaskell-data-env";
    haskellPackages = pkgs.haskell.packages.ghc865;
    packages = import ./overlay/haskell-list.nix {inherit pkgs;};
    Rpackages = p: with p; [ ggplot2 dplyr xts purrr cmaes cubature
                             reshape2
                           ];    
    inline-r = true;
  };

  voila =  pkgs.callPackage "/home/gtrun/project/hardenedlinux-zeek-script/NSM-data-analysis/pkgs/python/voila" {};
  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell IRkernel ];
      #directory = ./jupyterlab;
      extraJupyterPath = pkgs:
      "${voila}/bin";
      directory = jupyter.mkDirectoryWith {
        extensions = [
          "@jupyter-widgets/jupyterlab-manager@2.0"
          #"${ihaskell_labextension}" does not work
        ];
     };
    };
in
pkgs.buildEnv rec {
  name = "Jupyter-data-Env";
  buildInputs = [pkgs.makeWrapper];
  paths = [ jupyterEnvironment
            pkgs.python3Packages.ipywidgets
            env.generateDirectory
            voila
          ];
}
