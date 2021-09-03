{ pkgs }:
with pkgs;
let
  python-custom = pkgs.machlib.mkPython rec {
    python = "python38";
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

  juliaPackages = builtins.getEnv "DEVSHELL_ROOT" + "/packages/julia/";
  iJulia = jupyterWith.kernels.iJuliaWith rec {
    name = "Julia-data-env";
    inherit pkgs;
    #Project.toml directory
    activateDir = juliaPackages;
    # JuliaPackages directory
    JULIA_DEPOT_PATH = juliaPackages + "/julia_depot";
    extraEnv = {
      #TODO NEXT VERSION or PATCH
      #https://github.com/JuliaLang/julia/issues/40585#issuecomment-834096490
      PYTHON = "${python-custom}/bin/python";
    };
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

  JULIA_DEPOT_PATH = juliaPackages + "/julia_depot";

  PYTHON = "${python-custom}/bin/python";

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
