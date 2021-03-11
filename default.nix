let
  inherit (inputflake) loadInput flakeLock;
  inputflake = import ./nix/lib.nix { };
  pkgs = (import (loadInput flakeLock.nixpkgs)) { inherit overlays; config = { allowUnfree = true; allowBroken = true; }; };
  #pkgs = (import (loadInput flakeLock.python37)) { inherit overlays; config = { allowUnfree = true; allowBroken = true; }; }; #tensorflow support
  jupyter = (import (loadInput flakeLock.jupyterWith)) { inherit pkgs; };
  env = (import ((loadInput flakeLock.jupyterWith) + "/lib/directory.nix")) {
    inherit pkgs Rpackages;
  };

  mach-nix = (import (loadInput flakeLock.mach-nix)) { };
  python-custom = mach-nix.mkPython rec {
    requirements = builtins.readFile ./nix/python-environment.txt;
  };

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
    python3 = python-custom.python;
    packages = python-custom.python.pkgs.selectPkgs;
  };

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

  julia_wrapped = import ./nix/julia2nix-env { };
  currentDir = builtins.getEnv "PWD";
  iJulia = jupyter.kernels.iJuliaWith {
    name = "Julia-data-env";
    inherit julia_wrapped;
    directory = julia_wrapped.depot;
    activateDir = currentDir + "/nix/julia2nix-env";
  };

  iNix = jupyter.kernels.iNixKernel {
    name = "nix-kernel";
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell iJulia iNix ];
      directory = jupyter.mkDirectoryWith {
        extensions = [
          "jupyterlab-jupytext@1.2.2"
          "@jupyterlab/server-proxy"
          "@jupyter-widgets/jupyterlab-manager@2"
        ];
      };
      extraPackages = p: with p;[
        python-custom.python.pkgs."jupytext"
        python-custom.python.pkgs."jupyter-server-proxy"
      ];
      extraJupyterPath = p: "${python-custom.python.pkgs."jupytext"}/${p.python3.sitePackages}:${python-custom.python.pkgs."jupyter-server-proxy"}/${p.python3.sitePackages}:${p.python3Packages.aiohttp}/${p.python3.sitePackages}:${p.python3Packages.typing-extensions}/${p.python3.sitePackages}:${p.python3Packages.typing-extensions}/${p.python3.sitePackages}:${python-custom.python.pkgs.simpervisor}/${p.python3.sitePackages}:${python-custom.python.pkgs."multidict"}/${p.python3.sitePackages}:${python-custom.python.pkgs."yarl"}/${p.python3.sitePackages}:${python-custom.python.pkgs."async-timeout"}/${p.python3.sitePackages}";
    };
in
pkgs.mkShell rec {
  name = "Jupyter-data-Env";
  buildInputs = [
    jupyterEnvironment
  ];

  JULIA_DEPOT_PATH = ".julia_depot";
  R_LIBS_SITE = "${builtins.readFile env.r-libs-site}";

  shellHook = ''
    sed -i 's|/nix/store/.*./bin/julia|${julia_wrapped}/bin/julia|' ./jupyter_notebook_config.py
    # export PYTHON="${toString iPython.kernelEnv}/bin/python"
    # export PYTHONPATH="${toString iPython.kernelEnv}/${pkgs.python3.sitePackages}/"
      #${jupyterEnvironment}/bin/jupyter-lab --ip
  '';
}
