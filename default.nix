let
  inherit (inputflake) loadInput flakeLock;
  inputflake = import ./nix/lib.nix { };
  pkgs = (import (loadInput flakeLock.nixpkgs)) { inherit overlays; config = { allowUnfree = true; allowBroken = true; }; };
  #pkgs = (import (loadInput flakeLock.python37)) { inherit overlays; config = { allowUnfree = true; allowBroken = true; }; }; #tensorflow support
  jupyter = (import (loadInput flakeLock.jupyterWith)) { inherit pkgs; };
  env = (import ((loadInput flakeLock.jupyterWith) + "/lib/directory.nix")) { inherit pkgs Rpackages; };

  overlays = [
    # Only necessary for Haskell kernel
    (import ./nix/overlays/python-overlay.nix)
    (import ./nix/overlays/package-overlay.nix)
    (import ./nix/overlays/haskell-overlay.nix)
    (import ((loadInput flakeLock.nixpkgs-hardenedlinux) + "/nix/python-packages-overlay.nix"))
  ];

  Rpackages = p: with p; [
    ggplot2
    dplyr
    xts
    purrr
    cmaes
    cubature
    reshape2
  ];

  iPython = jupyter.kernels.iPythonWith {
    name = "Python-data-env";
    packages = import ./nix/overlays/python-packages-list.nix {
      inherit pkgs;
      MachineLearning = true;
      DataScience = true;
      Financial = false;
      Graph = true;
      SecurityAnalysis = false;
    };
    ignoreCollisions = true;
  };

  IRkernel = jupyter.kernels.iRWith {
    name = "IRkernel-data-env";
    packages = import ./nix/overlays/R-packages-list.nix { inherit pkgs; };
  };

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "ihaskell-data-env";
    extraIHaskellFlags = "--codemirror Haskell"; # for jupyterlab syntax highlighting
    packages = import ./nix/overlays/haskell-packages-list.nix {
      inherit pkgs;
      Diagrams = true;
      Hasktorch = false;
      InlineC = false;
      Matrix = true;
    };
    r-libs-site = env.r-libs-site;
    r-bin-path = env.r-bin-path;
  };

  julia_wrapped = import ./nix/julia2nix { };
  iJulia = jupyter.kernels.iJuliaWith {
    name = "Julia-data-env";
    inherit julia_wrapped;
    directory = julia_wrapped.depot;
  };

  iNix = jupyter.kernels.iNixKernel {
    name = "nix-kernel";
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell IRkernel iJulia iNix ];
      directory = jupyter.mkDirectoryWith {
        extensions = [
          "jupyterlab-jupytext@1.2.2"
          "@jupyterlab/server-proxy"
          "@jupyter-widgets/jupyterlab-manager@2"
        ];
      };

      extraPackages = p: with p;[
        python3Packages.jupytext
        pkgs.pandoc
        python3Packages.jupyter-server-proxy
        python3Packages.aiohttp
        python3Packages.simpervisor
      ];
      extraJupyterPath = p: "${p.python3Packages.jupytext}/${p.python3.sitePackages}:${p.python3Packages.jupyter-server-proxy}/${p.python3.sitePackages}:${p.python3Packages.aiohttp}/${p.python3.sitePackages}:${p.python3Packages.simpervisor}/${p.python3.sitePackages}:${p.python3Packages.multidict}/${p.python3.sitePackages}:${p.python3Packages.yarl}/${p.python3.sitePackages}:${p.python3Packages.async-timeout}/${p.python3.sitePackages}";
    };
in
pkgs.mkShell rec {
  name = "Jupyter-data-Env";
  buildInputs = [
    jupyterEnvironment
    pkgs.python3Packages.jupytext
  ];

  shellHook = ''
      export R_LIBS_SITE=${builtins.readFile env.r-libs-site}
      export PATH="${pkgs.lib.makeBinPath ([ env.r-bin-path ])}:$PATH"
      sed -i 's|/nix/store/.*./bin/julia|${julia_wrapped}/bin/julia|' ./jupyter_notebook_config.py
      # export PYTHON="${toString iPython.kernelEnv}/bin/python"
      # export PYTHONPATH="${toString iPython.kernelEnv}/${pkgs.python3.sitePackages}/"
    #${jupyterEnvironment}/bin/jupyter-lab --ip
  '';
}
