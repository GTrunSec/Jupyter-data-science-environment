{ pkgs }:
with pkgs;
let
  python-custom = pkgs.machlib.mkPython rec {
    requirements = builtins.readFile ../packages/python-packages.txt;
  };

  iPython = jupyterWith.kernels.iPythonWith {
    name = "Python-data-env";
    python3 = python-custom.python;
    packages = python-custom.python.pkgs.selectPkgs;
    ignoreCollisions = true;
  };


  iHaskell = jupyterWith.kernels.iHaskellWith {
    extraIHaskellFlags = "--codemirror Haskell"; # for jupyterlab syntax highlighting
    name = "ihaskell-flake";
    packages = import ../packages/haskell-packages.nix {
      inherit pkgs;
      Diagrams = true;
      Hasktorch = false;
      InlineR = false;
      Matrix = true;
    };
  };

  iJulia =
    let
      currentDir = builtins.getEnv "DEVSHELL_ROOT";
    in
    jupyterWith.kernels.iJuliaWith rec {
      name = "Julia-data-env";
      #Project.toml directory
      activateDir = currentDir + "/packages/julia";
      # JuliaPackages directory
      JULIA_DEPOT_PATH = activateDir + "/julia_depot";
      extraEnv = { };
    };


  iNix = jupyterWith.kernels.iNixKernel {
    name = "nix-kernel";
    nix = pkgs.nixFlakes;
  };

  jupyterEnvironment =
    let
      mapPkgs = v: "${lib.concatImapStringsSep ":" (pos: x: x + "/${pkgs.python3.sitePackages}") v}";
    in
    jupyterWith.jupyterlabWith rec {
      kernels = [ iPython iHaskell iJulia iNix ];
      directory = "./.jupyterlab";
      extraPackages = p: with p;[
        python-custom.python.pkgs."jupytext"
        python-custom.python.pkgs."jupyter-server-proxy"
      ];
      extraJupyterPath = p: mapPkgs (lib.attrVals [
        "jupytext"
        #"jupyter-server-proxy"
      ]
        python-custom.python.pkgs);
    };
in
pkgs.mkShell rec {
  buildInputs = [
    jupyterEnvironment
    iJulia.runtimePackages
    iPython.runtimePackages
  ];

  JULIA_DEPOT_PATH = builtins.getEnv "DEVSHELL_ROOT" + "/packages/julia/julia_depot";

  shellHook = ''
    if [ ! -d "$DEVSHELL_ROOT/.jupyterlab" ]; then
       jupyter lab build
    fi
    # ln -sfT ${iPython.spec}/kernels/ipython_Python-data-env ~/.local/share/jupyter/kernels/ipython_Symlink
    # ln -sfT ${iHaskell.spec}/kernels/ihaskell_ihaskell-flake ~/.local/share/jupyter/kernels/iHaskell-Symlink
    # ln -sfT ${iJulia.spec}/kernels/julia_Julia-data-env ~/.local/share/jupyter/kernels/iJulia-Symlink
    # ln -sfT ${iNix.spec}/kernels/inix_nix-kernel/  ~/.local/share/jupyter/kernels/INix-Symlink
  '';
}
