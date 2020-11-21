let
  inherit (inputflake) loadInput flakeLock;
  inputflake = import ../nix/lib.nix {};
  pkgs = (import (loadInput flakeLock.nixpkgs)) { inherit overlays; config={ allowUnfree=true; allowBroken=true; };};

  jupyter = (import (loadInput flakeLock.jupyterWith)){ inherit pkgs;};
  env = (import ((loadInput flakeLock.jupyterWith) + "/lib/directory.nix")){ inherit pkgs Rpackages;};

  overlays = [
    # Only necessary for Haskell kernel
    (import ../overlays/python-overlay.nix)
    (import ../overlays/package-overlay.nix)
    (import ../overlays/julia-overlay.nix)
    (import ../overlays/haskell-overlay.nix)
  ];


  Rpackages = p: with p; [ ggplot2 dplyr xts purrr cmaes cubature
                           reshape2
                         ];

  iPython = jupyter.kernels.iPythonWith {
    python3 = pkgs.callPackage ../overlays/python-self-packages.nix { inherit pkgs;};
    name = "Python-data-env";
    packages = import ../overlays/python-packages-list.nix { inherit pkgs;
                                                            MachineLearning = true;
                                                            DataScience = true;
                                                            Financial = true;
                                                            Graph =  true;
                                                            SecurityAnalysis = true;
                                                          };
    ignoreCollisions = true;
  };

  IRkernel = jupyter.kernels.iRWith {
    name = "IRkernel-data-env";
    packages = import ../overlays/R-packages-list.nix { inherit pkgs;};
  };

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "ihaskell-data-env";
    extraIHaskellFlags = "--codemirror Haskell";  # for jupyterlab syntax highlighting
    packages = import ../overlays/haskell-packages-list.nix { inherit pkgs;
                                                             Diagrams = true; Hasktorch = true; InlineC = false; Matrix = true;
                                                           };
    r-libs-site = env.r-libs-site;
    r-bin-path = env.r-bin-path;
  };

  currentDir = builtins.getEnv "PWD";
  iJulia = jupyter.kernels.iJuliaWith {
    name = "Julia-data-env";
    directory = currentDir + "/.julia_pkgs";
    NUM_THREADS = 24;
    cuda = true;
    cudaVersion = pkgs.cudatoolkit_10_2;
    nvidiaVersion = pkgs.linuxPackages.nvidia_x11;
    extraPackages = p: with p;[
      # GZip.jl # Required by DataFrames.jl
      gzip
      zlib
    ];
  };

  iNix = jupyter.kernels.iNixKernel {
    name = "nix-kernel";
  };


  iRust = jupyter.kernels.rustWith {
    name = "data-rust-env";
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell IRkernel iJulia iNix iRust ];
      directory = jupyter.mkDirectoryWith {
        extensions = [
          "@krassowski/jupyterlab-lsp@1.1.2"
        ];
      };
      extraPackages = p: with p;[ python3Packages.jupyter_lsp python3Packages.python-language-server ];
    };

in
pkgs.buildEnv rec {
  name = "Jupyter-data-build-Env";
  paths = [ jupyterEnvironment
                  pkgs.python3Packages.ipywidgets
                  pkgs.python3Packages.jupyterlab_git
                  pkgs.python3Packages.jupyter_lsp
                  pkgs.python3Packages.python-language-server
                  env.generateDirectory
                  iJulia.runtimePackages
                ];
}
