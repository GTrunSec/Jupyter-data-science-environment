let
  inherit (inputflake) loadInput flakeLock;
  inputflake = import ./nix/lib.nix { };
  pkgs = (import (loadInput flakeLock.nixpkgs)) { inherit overlays; config = { allowUnfree = true; allowBroken = true; }; };
  #pkgs = (import (loadInput flakeLock.python37)) { inherit overlays; config={ allowUnfree=true; allowBroken=true; };};
  jupyter = (import (loadInput flakeLock.jupyterWith)) { inherit pkgs; };
  #jupyter = (import ../jupyterWith){ inherit pkgs;};
  env = (import ((loadInput flakeLock.jupyterWith) + "/lib/directory.nix")) { inherit pkgs Rpackages; };

  mach-nix = (import (loadInput flakeLock.mach-nix)) {
    pypiDataRev = "2205d5a0fc9b691e7190d18ba164a3c594570a4b";
    pypiDataSha256 = "1aaylax7jlwsphyz3p73790qbrmva3mzm56yf5pbd8hbkaavcp9g";
  };
  python-custom = mach-nix.mkPython rec {
    requirements = builtins.readFile ./nix/python-environment.txt;
  };

  overlays = [
    (import ./nix/overlays/python-overlay.nix)
    (import ./nix/overlays/package-overlay.nix)
    (import ./nix/overlays/haskell-overlay.nix)
    (import ((loadInput flakeLock.nixpkgs-hardenedlinux) + "/nix/python-packages-overlay.nix"))
  ];

  iPython = jupyter.kernels.iPythonWith {
    name = "Python-data-env";
    python3 = python-custom.python;
    packages = python-custom.python.pkgs.selectPkgs;
  };

  Rpackages = p: with p; [ ggplot2 ];

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "ihaskell-data-env";
    extraIHaskellFlags = "--codemirror Haskell"; # for jupyterlab syntax highlighting
    packages = import ./nix/overlays/haskell-packages-list.nix {
      inherit pkgs;
      Diagrams = false;
      Hasktorch = false;
      InlineC = false;
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
      kernels = [ iPython iHaskell iNix iRust CXX iJulia ];
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
