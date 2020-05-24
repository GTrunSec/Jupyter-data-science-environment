let
  jupyterLib = builtins.fetchGit {
    url = https://github.com/GTrunSec/jupyterWith;
    rev = "6fcde5cbe1bcca1eccf80721996c61f3d50bc3e8";
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


  env = (import (jupyterLib + "/lib/directory.nix")){ inherit pkgs;};
  
  pkgs = (import (jupyterLib + "/nix/nixpkgs.nix")) { inherit overlays; config={ allowUnfree=true; allowBroken=true; };};

  jupyter = import jupyterLib {pkgs=pkgs;};
  
  ihaskell_labextension = pkgs.fetchurl {
    url = "https://github.com/GTrunSec/ihaskell_labextension/releases/download/fetchurl/package.tar.gz";
    sha256 = "0i17yd3b9cgfkjxmv9rdv3s31aip6hxph5x70s04l9xidlvsp603";
  };

  iPython = jupyter.kernels.iPythonWith {
    python3 = pkgs.callPackage ./overlay/own-python.nix { inherit pkgs;};
    name = "Python-data-env";
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

  currentDir = builtins.getEnv "PWD";
  iJulia = jupyter.kernels.iJuliaWith {
    name =  "Julia-data-env";
    directory = currentDir + "/.julia_pkgs";
    nixpkgs =  import (builtins.fetchTarball "https://github.com/GTrunSec/nixpkgs/tarball/39247f8d04c04b3ee629a1f85aeedd582bf41cac"){};
    NUM_THREADS = 8;
    extraPackages = p: with p;[   # GZip.jl # Required by DataFrames.jl
      gzip
      zlib
    ];
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell IRkernel iJulia ];
      directory = ./jupyterlab;
      extraPackages = p: with p;[ python3Packages.jupyterlab_git python3Packages.jupyter_lsp python3Packages.python-language-server ];
      extraJupyterPath = p: "${p.python3Packages.jupyterlab_git}/lib/python3.7/site-packages:${p.python3Packages.jupyter_lsp}/lib/python3.7/site-packages:${p.python3Packages.python-language-server}/lib/python3.7/site-packages";
    };

in
pkgs.mkShell rec {
  name = "Jupyter-data-Env";
  buildInputs = [ jupyterEnvironment
                  pkgs.python3Packages.ipywidgets
                  pkgs.python3Packages.jupyterlab_git
                  pkgs.python3Packages.python-language-server
                  pkgs.python3Packages.jupyter_lsp
                  env.generateDirectory
                  iJulia.InstalliJulia
                  iJulia.julia_wrapped
                  iJulia.Install_JuliaCUDA
                ];
  
  shellHook = ''
     ${pkgs.python3Packages.jupyter_core}/bin/jupyter nbextension install --py widgetsnbextension --user
     ${pkgs.python3Packages.jupyter_core}/bin/jupyter nbextension enable --py widgetsnbextension
      ${pkgs.python3Packages.jupyter_core}/bin/jupyter serverextension enable --py jupyterlab_git
      ${pkgs.python3Packages.jupyter_core}/bin/jupyter serverextension enable --py jupyter_lsp
      if [ ! -f "./jupyterlab/extensions/ihaskell_jupyterlab-0.0.7.tgz" ]; then
          ${env.generateDirectory}/bin/generate-directory ${ihaskell_labextension}
        if [ ! -f "./jupyterlab/extensions/jupyter-widgets-jupyterlab-manager-2.0.0.tgz" ]; then
       ${env.generateDirectory}/bin/generate-directory @jupyter-widgets/jupyterlab-manager@2.0
       ${env.generateDirectory}/bin/generate-directory @jupyterlab/git
       ${env.generateDirectory}/bin/generate-directory @krassowski/jupyterlab-lsp
     fi
  fi
    #${jupyterEnvironment}/bin/jupyter-lab
    '';
}
