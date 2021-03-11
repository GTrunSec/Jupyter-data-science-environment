let
  inherit (inputflake) loadInput flakeLock;
  inputflake = import ./nix/lib.nix { };
  pkgs = (import (loadInput flakeLock.nixpkgs)) { inherit overlays; config = { allowUnfree = true; allowBroken = true; }; };
  #pkgs = (import (loadInput flakeLock.python37)) { inherit overlays; config={ allowUnfree=true; allowBroken=true; };};
  jupyter = (import (loadInput flakeLock.jupyterWith)) { inherit pkgs; };
  #jupyter = (import ../jupyterWith){ inherit pkgs;};
  env = (import ((loadInput flakeLock.jupyterWith) + "/lib/directory.nix")) { inherit pkgs Rpackages; };


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
    # packages = import ./nix/overlays/haskell-packages-list.nix {
    #   inherit pkgs;
    #   Diagrams = true;
    #   Hasktorch = true;
    #   InlineC = false;
    #   Matrix = true;
    # };
    r-libs-site = env.r-libs-site; #
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


  iRust = jupyter.kernels.rustWith {
    name = "data-rust-env";
  };

  CXX = jupyter.kernels.xeusCling {
    name = "cxx-kernel";
    extraFlag = "c++17";
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell iJulia iNix iRust ];
      directory = jupyter.mkDirectoryWith {
        extensions = [
          "jupyterlab-jupytext"
          "@jupyterlab/server-proxy"
        ];
      };
      extraPackages = p: with p;[
        python-custom.python.pkgs."jupytext"
        python-custom.python.pkgs."jupyter-server-proxy"
      ];
      extraJupyterPath = p: "${python-custom.python.pkgs."jupytext"}/${p.python3.sitePackages}:${python-custom.python.pkgs."jupyter-server-proxy"}/${p.python3.sitePackages}:${p.python3Packages.aiohttp}/${p.python3.sitePackages}::${p.python3Packages.typing-extensions}/${p.python3.sitePackages}:${python-custom.python.pkgs.simpervisor}/${p.python3.sitePackages}:${python-custom.python.pkgs."multidict"}/${p.python3.sitePackages}:${python-custom.python.pkgs."yarl"}/${p.python3.sitePackages}:${python-custom.python.pkgs."async-timeout"}/${p.python3.sitePackages}";
    };

in
pkgs.mkShell rec {
  name = "Jupyter-data-Env";
  buildInputs = [
    jupyterEnvironment
    iPython.runtimePackages
  ];
  #https://discourse.nixos.org/t/system-with-nixos-how-to-add-another-extra-distribution
  R_LIBS_SITE = "${builtins.readFile env.r-libs-site}";
  JULIA_DEPOT_PATH = ".julia_depot";
  shellHook = ''
      sed -i 's|/nix/store/.*./bin/julia|${julia_wrapped}/bin/julia|' ./jupyter_notebook_config.py
    ln -sfT ${iPython.spec}/kernels/ipython_Python-data-env ~/.local/share/jupyter/kernels/ipython_Python-data-env
      ln -sfT ${iHaskell.spec}/kernels/ihaskell_ihaskell-data-env ~/.local/share/jupyter/kernels/iHaskell-data-env
      ln -sfT ${iJulia.spec}/kernels/julia_Julia-data-env ~/.local/share/jupyter/kernels/iJulia-data-env
      ln -sfT ${iNix.spec}/kernels/inix_nix-kernel/  ~/.local/share/jupyter/kernels/INix-data-env
      ln -sfT ${iRust.spec}/kernels/rust_data-rust-env  ~/.local/share/jupyter/kernels/IRust-data-env
  '';
}
