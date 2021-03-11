let
  inherit (inputflake) loadInput flakeLock;
  inputflake = import ./nix/lib.nix { };
  pkgs = (import (loadInput flakeLock.nixpkgs)) { inherit overlays; config = { allowUnfree = true; allowBroken = true; }; };
  #pkgs = (import (loadInput flakeLock.python37)) { inherit overlays; config={ allowUnfree=true; allowBroken=true; };};
  jupyter = (import (loadInput flakeLock.jupyterWith)) { inherit pkgs; };
  #jupyter = (import ../jupyterWith){ inherit pkgs;};
  env = (import ((loadInput flakeLock.jupyterWith) + "/lib/directory.nix")) { inherit pkgs Rpackages; };

  overlays = [
    (import ./nix/overlays/python-overlay.nix)
    (import ./nix/overlays/package-overlay.nix)
    (import ./nix/overlays/haskell-overlay.nix)
    (import ((loadInput flakeLock.nixpkgs-hardenedlinux) + "/nix/python-packages-overlay.nix"))
  ];

  iPython = jupyter.kernels.iPythonWith {
    name = "Python-kernel";
    packages = import ./nix/overlays/python-packages-list.nix {
      inherit pkgs;
    };
    ignoreCollisions = true;
  };

  IRkernel = jupyter.kernels.iRWith {
    name = "IRkernel";
    packages = import ./nix/overlays/R-packages-list.nix { inherit pkgs; };
  };

  Rpackages = p: with p; [ ggplot2 ];

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "haskell";
    packages = import ./nix/overlays/haskell-packages-list.nix {
      inherit pkgs;
      Diagrams = true;
      Hasktorch = true;
      InlineC = true;
      Matrix = true;
    };
    r-libs-site = env.r-libs-site;
    r-bin-path = env.r-bin-path;
  };

  iNix = jupyter.kernels.iNixKernel {
    name = "nix-kernel";
  };

  iRust = jupyter.kernels.rustWith {
    name = "data-rust-env";
  };

  CXX = jupyter.kernels.xeusCling {
    name = "cxx-kernel";
  };

  julia_wrapped = import ./nix/julia2nix-env { };
  iJulia = jupyter.kernels.iJuliaWith {
    name = "Julia-data-env";
    inherit julia_wrapped;
    directory = julia_wrapped.depot;
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell IRkernel iNix iRust CXX iJulia ];
    };
in
{
  Jupyter-data-science-environment = pkgs.buildEnv {
    name = "Jupyter-data-science-environment";
    paths = [
      jupyterEnvironment
    ];
  };
}
