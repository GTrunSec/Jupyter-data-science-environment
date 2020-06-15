let
  jupyterLib = import <jupyterLib>;
      haskTorchSrc = import <haskTorchSrc>;
        hasktorchOverlay = (import <haskTorchSrc/nix/shared.nix> { compiler = "ghc883"; }).overlayShared;

  haskellOverlay = import ./overlay/haskell-overlay.nix;
  overlays = [
    # Only necessary for Haskell kernel
    (import ./overlay/python-overlay.nix)
    (import ./overlay/package-overlay.nix)
    haskellOverlay
    hasktorchOverlay
    (import ./overlay/julia.nix)
  ];

  pkgs = import <jupyterLib-nixpkgs> { inherit overlays; config={ allowUnfree=true; allowBroken=true;};};

  jupyter = import <jupyterLib> {pkgs=pkgs;};
  ihaskell_labextension = pkgs.fetchurl {
    url = "https://github.com/GTrunSec/ihaskell_labextension/releases/download/fetchurl/package.tar.gz";
    sha256 = "0i17yd3b9cgfkjxmv9rdv3s31aip6hxph5x70s04l9xidlvsp603";
  };

  iPython = jupyter.kernels.iPythonWith {
    python3 = pkgs.callPackage ./overlay/python-self-packages.nix {};
    name = "Python-kernel";
    packages = import ./overlay/python-packages-list.nix {inherit pkgs;};
    ignoreCollisions = true;
  };

    IRkernel = jupyter.kernels.iRWith {
      name = "IRkernel";
      packages = import ./overlay/R-packages-list.nix {inherit pkgs;};
  };

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "haskell";
    haskellPackages = pkgs.haskell.packages.ghc883;
    packages = import ./overlay/haskell-packages-list.nix {inherit pkgs;};
  };

  iNix = jupyter.kernels.iNixKernel {
    name = "nix-kernel";
  };

  iJulia = jupyter.kernels.iJuliaWith {
    name =  "Julia-data-env";
    directory = "./julia-pkgs";
    NUM_THREADS = 24;
    cuda = true;
    cudaVersion = pkgs.cudatoolkit_10_2;
    nvidiaVersion = pkgs.linuxPackages.nvidia_x11;
    extraPackages = p: with p;[   # GZip.jl # Required by DataFrames.jl
      gzip
      zlib
    ];
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell IRkernel iJulia iNix ];
    };
in
{
  Jupyter-data-science-environment = pkgs.buildEnv {
    name = "Jupyter-data-science-environment";
    paths = [ jupyterEnvironment
              pkgs.python3Packages.ipywidgets
            ];
  };
}
