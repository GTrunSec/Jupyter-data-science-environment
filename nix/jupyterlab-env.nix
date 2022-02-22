{
  pkgs,
  julia_depot_path ? (builtins.getEnv "PRJ_ROOT" + "/packages/julia/JuliaTutorial"),
}:
with pkgs; let
  python-custom = pkgs.mach-nix.mkPython rec {
    python = "python3";
    requirements = builtins.readFile ../packages/python-packages.txt;
    # providers = {
    #   cffi = "nixpkgs";
    #   pycparser= "nixpkgs";
    # };
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

  iJulia = jupyterWith.kernels.iJuliaWith {
    name = "Julia-data-env";
    package = pkgs.julia_17-bin;
    #Project.toml directory
    activateDir = julia_depot_path;
    # JuliaPackages directory
    JULIA_DEPOT_PATH = julia_depot_path + "/julia_depot";
    extraEnv = {
      PYTHON = "${python-custom}/bin/python";
    };
  };

  iNix = jupyterWith.kernels.iNixKernel {
    name = "nix-kernel";
    nix = pkgs.nixFlakes;
  };

  jupyterEnvironment = let
    mapPkgs = v: "${lib.concatImapStringsSep ":" (pos: x: x + "/${pkgs.python3.sitePackages}") v}";
  in
    jupyterWith.jupyterlabWith rec {
      kernels = [iPython iHaskell iJulia iNix];
      directory = "./jupyterlab";
      extraPackages = p:
        with p; [
          python-custom.python.pkgs."jupytext"
        ];
      extraJupyterPath = p:
        mapPkgs (lib.attrVals [
          "jupytext"
          # "jupyter-server-proxy"
        ]
        python-custom.python.pkgs);
    };
in
  pkgs.mkShell rec {
    buildInputs =
      [
        jupyterEnvironment
        iJulia.runtimePackages
        iPython.runtimePackages
        python-custom.python.pkgs."jupytext"
      ]
      ++ jupyterEnvironment.env.buildInputs;

    JULIA_DEPOT_PATH = julia_depot_path + "/julia_depot";

    PYTHON = "${python-custom}/bin/python";

    shellHook = ''
      # ln -sfT ${iPython.spec}/kernels/ipython_Python-data-env ~/.local/share/jupyter/kernels/ipython_Symlink
      # ln -sfT ${iHaskell.spec}/kernels/ihaskell_ihaskell-flake ~/.local/share/jupyter/kernels/iHaskell-Symlink
      # ln -sfT ${iJulia.spec}/kernels/julia_Julia-data-env ~/.local/share/jupyter/kernels/iJulia-Symlink
      # ln -sfT ${iNix.spec}/kernels/inix_nix-kernel/  ~/.local/share/jupyter/kernels/INix-Symlink
    '';
  }
