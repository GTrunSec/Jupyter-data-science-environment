let
  jupyterLib = builtins.fetchGit {
    url = https://github.com/GTrunSec/jupyterWith;
    rev = "ce6b72643cf74c2c278224cb29c59a24fedf7c25";
    ref = "current";
  };

  haskTorchSrc = builtins.fetchGit {
    url = https://github.com/hasktorch/hasktorch;
    rev = "7e017756fd9861218bf2f804d1f7eaa4d618eb01";
    ref = "master";
  };

  hasktorchOverlay = (import (haskTorchSrc + "/nix/shared.nix") { compiler = "ghc865"; }).overlayShared;
  haskellOverlay = import ./overlay/old-haskell.nix;
  overlays = [
    # Only necessary for Haskell kernel
    (import ./overlay/python.nix)
    haskellOverlay
    hasktorchOverlay
  ];


  
  env = (import (jupyterLib + "/lib/directory.nix")){ inherit pkgs;};

  #pkgs = (import (jupyterLib + "/nix/nixpkgs.nix")) { inherit overlays; config={ allowUnfree=true; allowBroken=true;};};
  pkgs = (import ./nix/old-nixpkgs.nix) { inherit overlays; config={ allowUnfree=true; allowBroken=true; };};
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

  overlay_julia = [ (import ./overlay/julia.nix)
                  ];

  currentDir = builtins.getEnv "PWD";
  iJulia = jupyter.kernels.iJuliaWith {
    name =  "Julia-test";
    directory = currentDir + "/.julia_pkgs";
    nixpkgs =  import (builtins.fetchTarball "https://github.com/GTrunSec/nixpkgs/tarball/3fac6bbcf173596dbd2707fe402ab6f65469236e"){ overlays=overlay_julia;};
    extraPackages = p: with p;[   # GZip.jl # Required by DataFrames.jl
      gzip
      zlib
    ];
  };


  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell IRkernel
                  iJulia
                ];
      directory = ./jupyterlab;
      extraPackages = p: [p.python3Packages.jupyterlab_git];
      extraJupyterPath = p: "${p.python3Packages.jupyterlab_git}/lib/python3.7/site-packages";
    };

in
pkgs.buildEnv rec {
  name = "Jupyter-data-Env";
  buildInputs = [pkgs.makeWrapper];
  paths = [ jupyterEnvironment
            pkgs.python3Packages.ipywidgets
            env.generateDirectory
            pkgs.python3Packages.jupyterlab_git
            env.generateDirectory
            iJulia.julia_wrapped
            pkgs.R
          ];
}
