let
  jupyterLib = builtins.fetchGit {
    url = https://github.com/tweag/jupyterWith;
    rev = "7a6716f0c0a5538691a2f71a9f12b066bce7d55c";
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
    name = "agriculture";
    packages = import ./overlay/python-list.nix {inherit pkgs;};
  };

  IRkernel = jupyter.kernels.iRWith {
    name = "IRkernel";
    packages = import ./overlay/R-list.nix {inherit pkgs;};
   };

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "haskell";
    haskellPackages = pkgs.haskell.packages.ghc865;
    packages = import ./overlay/haskell-list.nix {inherit pkgs;};
  };


  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell IRkernel ];
      directory = ./jupyterlab;
      # directory = jupyter.mkDirectoryWith {
        # extensions = [
        #   "@jupyter-widgets/jupyterlab-manager@2.0"
        #   #"${ihaskell_labextension}" does not work
        # ];
     # };
    };
  my-overlay = pkgs.fetchFromGitHub {
    owner = "hardenedlinux";
    repo = "NSM-data-analysis";
    rev = "576e588e3b1e4f2738f4b7e2ca55c59e8be7d689";
    sha256 = "118h2hi5ib9rfbk3kclvi273zf4zqw1igxxi846amj8096wkcfbv";
  };

  voila =  pkgs.callPackage (my-overlay + "/pkgs/python/voila") {};
in
pkgs.mkShell rec {
  name = "analysis-arg";
  buildInputs = [ jupyterEnvironment
                  pkgs.python3Packages.ipywidgets
                  env.generateDirectory
                  (pkgs.python.buildEnv.override {
                    ignoreCollisions = true;
                    extraLibs = with pkgs.python3Packages; [
                      voila
                    ];
                  })
                ];

  shellHook = ''
    ${pkgs.python3Packages.jupyter_core}/bin/jupyter nbextension install --py widgetsnbextension --user
    ${pkgs.python3Packages.jupyter_core}/bin/jupyter nbextension enable --py widgetsnbextension
      if [ ! -f "./jupyterlab/extensions/ihaskell_jupyterlab-0.0.7.tgz" ]; then
    ${env.generateDirectory}/bin/generate-directory ${ihaskell_labextension}
       if [ ! -f "./jupyterlab/extensions/jupyter-widgets-jupyterlab-manager-2.0.0.tgz" ]; then
       ${env.generateDirectory}/bin/generate-directory "@jupyter-widgets/jupyterlab-manager@2.0"
     fi
     exit
  fi
    #${jupyterEnvironment}/bin/jupyter-lab
    '';
}
