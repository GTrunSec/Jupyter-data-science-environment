let
  jupyterLib = import ../master-jupyter {};

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


  env = import ../master-jupyter/lib/directory.nix { inherit pkgs;};
  
  pkgs = import ../master-jupyter/nix { inherit overlays; config={ allowUnfree=true; allowBroken=true; ignoreCollisions = true;};};

  jupyter = import ../master-jupyter {pkgs=pkgs;};
  
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

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell IRkernel ];
      #directory = ./jupyterlab;
      directory = jupyter.mkDirectoryWith {
        extensions = [
          "@jupyter-widgets/jupyterlab-manager@2.0"
          #"${ihaskell_labextension}" does not work
        ];
     };
    };
in
pkgs.mkShell rec {
  name = "Jupyter-data-Env";
  buildInputs = [ jupyterEnvironment
                  pkgs.python3Packages.ipywidgets
                  env.generateDirectory
                  ];
  
  shellHook = ''
     ${pkgs.python3Packages.jupyter_core}/bin/jupyter nbextension install --py widgetsnbextension --user
     ${pkgs.python3Packages.jupyter_core}/bin/jupyter nbextension enable --py widgetsnbextension
  #     if [ ! -f "./jupyterlab/extensions/ihaskell_jupyterlab-0.0.7.tgz" ]; then
  #   ${env.generateDirectory}/bin/generate-directory ${ihaskell_labextension}
  #      if [ ! -f "./jupyterlab/extensions/jupyter-widgets-jupyterlab-manager-2.0.0.tgz" ]; then
  #      ${env.generateDirectory}/bin/generate-directory "@jupyter-widgets/jupyterlab-manager@2.0"
  #    fi
  #    exit
  # fi
    #${jupyterEnvironment}/bin/jupyter-lab
    '';
}