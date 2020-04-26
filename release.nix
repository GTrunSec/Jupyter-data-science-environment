let
  jupyterLib = import <jupyterLib>;
    my-overlay = import <my-overlay>;
      haskTorchSrc = import <haskTorchSrc>;
        hasktorchOverlay = (import <haskTorchSrc/nix/shared.nix> { compiler = "ghc865"; }).overlayShared;

  haskellOverlay = import ./overlay/haskell-overlay.nix;
  overlays = [
    # Only necessary for Haskell kernel
    (import ./overlay/python.nix)
    haskellOverlay
    hasktorchOverlay
  ];

  pkgs = import <jupyterLib-nix> { inherit overlays; config={ allowUnfree=true; allowBroken=true;};};

  jupyter = import <jupyterLib> {pkgs=pkgs;};
  voila =  pkgs.callPackage (<my-overlay> + "/pkgs/python/voila") {};
  ihaskell_labextension = pkgs.fetchurl {
    url = "https://github.com/GTrunSec/ihaskell_labextension/releases/download/fetchurl/package.tar.gz";
    sha256 = "0i17yd3b9cgfkjxmv9rdv3s31aip6hxph5x70s04l9xidlvsp603";
  };

  iPython = jupyter.kernels.iPythonWith {
    python3 = pkgs.callPackage ./overlay/own-python.nix {};
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
    };
in
{
  Jupyter-data-science-environment = pkgs.buildEnv {
    name = "Jupyter-data-science-environment";
    paths = [ jupyterEnvironment
              pkgs.python3Packages.ipywidgets
              voila
            ];
  };
}
