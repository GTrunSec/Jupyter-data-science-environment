let
  jupyterLib = builtins.fetchGit {
    url = https://github.com/GTrunSec/jupyterWith;
    rev = "a86535e13bbe211b7e6d7c6614c489861fb5afe5";
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
  };

  r-libs-site = pkgs.runCommand "r-libs-site" {
    buildInputs = with pkgs; [ R
                                  rPackages.ggplot2 rPackages.dplyr rPackages.xts rPackages.purrr rPackages.cmaes rPackages.cubature
                                  rPackages.reshape2
                                ];
  } ''echo $R_LIBS_SITE > $out'';


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
    export R_LIBS_SITE=${builtins.readFile r-libs-site}
    #${jupyterEnvironment}/bin/jupyter-lab
    '';
}
