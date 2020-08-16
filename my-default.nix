let
  jupyterLib = builtins.fetchGit {
    url = https://github.com/GTrunSec/jupyterWith;
    rev = "17186df7dbe7775b39e991e806d577f00363bdfe";
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


  env = (import (jupyterLib + "/lib/directory.nix")){ inherit pkgs;};
  
  pkgs = (import ./nix/nixpkgs.nix) { inherit overlays; config={ allowUnfree=true; allowBroken=true; };};

  jupyter = import jupyterLib {pkgs=pkgs;};
  
  ihaskell_labextension = pkgs.fetchurl {
    url = "https://github.com/GTrunSec/ihaskell_labextension/releases/download/fetchurl/ihaskell_jupyterlab-0.0.7.tgz";
    sha256 = "sha256-vtePEeXAclfWV1fNlNvOZ9uRrSaxQOzOMZ8PkCeWfCs=";
  };

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

  currentDir = builtins.getEnv "PWD";
  iJulia = jupyter.kernels.iJuliaWith {
    name = "Julia-data-env";
    directory = currentDir + "/.julia_pkgs";
    NUM_THREADS = 24;
    cuda = true;
    cudaVersion = pkgs.cudatoolkit_10_2;
    nvidiaVersion = pkgs.linuxPackages.nvidia_x11;
    extraPackages = p: with p;[
      # GZip.jl # Required by DataFrames.jl
      gzip
      zlib
    ];
  };

  iNix = jupyter.kernels.iNixKernel {
    name = "nix-kernel";
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell IRkernel iJulia iNix ];
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
                  pkgs.python3Packages.jupyter_lsp
                  pkgs.python3Packages.python-language-server
                  env.generateDirectory
                  iJulia.runtimePackages
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
