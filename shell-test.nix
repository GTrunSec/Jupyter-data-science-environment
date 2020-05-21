let
  jupyterLib = builtins.fetchGit {
    url = https://github.com/tweag/jupyterWith;
    rev = "dc8bb19f3f850c903fe481cbc7efc0982e6afd28";
    ref = "master";
  };

  overlays = [
    # Only necessary for Haskell kernel
    (import ./overlay/python.nix)
  ];

  pkgs = (import (jupyterLib + "/nix/nixpkgs.nix")) { inherit overlays; config={ allowUnfree=true; allowBroken=true; };};
  jupyter = import jupyterLib {pkgs=pkgs;};

  iPython = jupyter.kernels.iPythonWith {
    name = "notebook";
    python3 = pkgs.callPackage ./overlay/own-python.nix { inherit pkgs;};
    packages = import ./overlay/python-list.nix { inherit pkgs;};

    ##for geoip2 package
    ignoreCollisions = true;
  };

  iRKernel = jupyter.kernels.iRWith {
    name = "notebook";
    packages = p: with p; [
      cowplot
      dplyr
      ggplot2
    ];
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [
        iPython
        iRKernel
      ];
      directory = ./jupyterlab;
      extraPackages = p: [
        p.python3Packages.jupytext
      ];
      extraJupyterPath = p: "${p.python3Packages.jupytext}/lib/python3.7/site-packages";
    };
in
  jupyterEnvironment.env
