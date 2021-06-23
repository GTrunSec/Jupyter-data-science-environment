{ pkgs }:
with pkgs;
let
  python-custom = pkgs.machlib.mkPython rec {
    requirements = builtins.readFile ./packages/python-environment.txt;
  };

  iPython = jupyter.kernels.iPythonWith {
    name = "Python-data-env";
    python3 = python-custom.python;
    packages = python-custom.python.pkgs.selectPkgs;
    ignoreCollisions = true;
  };


  iHaskell = jupyter.kernels.iHaskellWith {
    extraIHaskellFlags = "--codemirror Haskell"; # for jupyterlab syntax highlighting
    name = "ihaskell-flake";
    packages = import ./packages/haskell-packages-list.nix {
      inherit pkgs;
      Diagrams = true;
      Hasktorch = false;
      InlineR = false;
      Matrix = true;
    };
  };

  iRust = jupyter.kernels.rustWith {
    name = "data-rust-env";
  };

  julia_wrapped = import ./nix/julia2nix-env { };
  currentDir = builtins.getEnv "PWD";
  iJulia = jupyter.kernels.iJuliaWith {
    name = "Julia-data-env";
    inherit julia_wrapped;
    directory = julia_wrapped.depot;
    activateDir = currentDir + "/nix/julia2nix-env";
    extraEnv = {
      JULIA_DEPOT_PATH = currentDir + "/.julia_depot";
    };
  };


  iNix = jupyter.kernels.iNixKernel {
    name = "nix-kernel";
    nix = pkgs.nixFlakes;
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell iJulia iNix iRust ];
      directory = "./.jupyterlab";
      extraPackages = p: with p;[
        python-custom.python.pkgs."jupytext"
        python-custom.python.pkgs."jupyter-server-proxy"
      ];
      extraJupyterPath = p: "${python-custom.python.pkgs."jupytext"}/${p.python3.sitePackages}:${python-custom.python.pkgs."jupyter-server-proxy"}/${p.python3.sitePackages}:${p.python3Packages.aiohttp}/${p.python3.sitePackages}:${p.python3Packages.typing-extensions}/${p.python3.sitePackages}:${p.python3Packages.typing-extensions}/${p.python3.sitePackages}:${python-custom.python.pkgs.simpervisor}/${p.python3.sitePackages}:${python-custom.python.pkgs."multidict"}/${p.python3.sitePackages}:${python-custom.python.pkgs."yarl"}/${p.python3.sitePackages}:${python-custom.python.pkgs."async-timeout"}/${p.python3.sitePackages}";
    };
in
pkgs.mkShell rec {
  buildInputs = [
    jupyterEnvironment
    iJulia.runtimePackages
    iPython.runtimePackages
  ];

  JULIA_DEPOT_PATH = "${./.}/julia_depot";

  shellHook = ''
    # jupyter lab build
       ln -sfT ${iPython.spec}/kernels/ipython_Python-data-env ~/.local/share/jupyter/kernels/ipython_Symlink
       ln -sfT ${iHaskell.spec}/kernels/ihaskell_ihaskell-flake ~/.local/share/jupyter/kernels/iHaskell-Symlink
       ln -sfT ${iJulia.spec}/kernels/julia_Julia-data-env ~/.local/share/jupyter/kernels/iJulia-Symlink
       ln -sfT ${iNix.spec}/kernels/inix_nix-kernel/  ~/.local/share/jupyter/kernels/INix-Symlink
       ln -sfT ${iRust.spec}/kernels/rust_data-rust-env  ~/.local/share/jupyter/kernels/IRust-Symlink
     #${jupyterEnvironment}/bin/jupyter-lab
  '';
}
