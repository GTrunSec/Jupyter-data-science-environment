let
  pkgs = (import ./nix/nixpkgs.nix) { inherit overlays; config={ allowUnfree=true; allowBroken=true; };};

  jupyterWith-locked = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.jupyterWith.locked;
  jupyterLib = builtins.fetchTarball {
    url = "https://github.com/${jupyterWith-locked.owner}/jupyterWith/archive/${jupyterWith-locked.rev}.tar.gz";
    sha256 = jupyterWith-locked.narHash;
  };

  jupyter = import jupyterLib {inherit pkgs;};
  env = (import (jupyterLib + "/lib/directory.nix")){ inherit pkgs Rpackages;};

  overlays = [
    # Only necessary for Haskell kernel
    (import ./overlays/python-overlay.nix)
    (import ./overlays/package-overlay.nix)
    (import ./overlays/julia-overlay.nix)
    (import ./overlays/haskell-overlay.nix)
  ];

  Rpackages = p: with p; [ ggplot2 dplyr xts purrr cmaes cubature
                           reshape2
                         ];

  iPython = jupyter.kernels.iPythonWith {
    python3 = pkgs.callPackage ./overlays/python-self-packages.nix { inherit pkgs; };
    name = "Python-data-env";
    packages = import ./overlays/python-packages-list.nix { inherit pkgs;
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
    packages = import ./overlays/R-packages-list.nix { inherit pkgs; };
  };

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "ihaskell-data-env";
    extraIHaskellFlags = "--codemirror Haskell";  # for jupyterlab syntax highlighting
    packages = import ./overlays/haskell-packages-list.nix { inherit pkgs;
                                                             Diagrams = true; Hasktorch = false; InlineC = false; Matrix = true;
                                                           };
    r-libs-site = env.r-libs-site;
    r-bin-path = env.r-bin-path;
  };

  ##julia part
  currentDir = builtins.getEnv "PWD";
  iJulia = jupyter.kernels.iJuliaWith {
    name =  "Julia-data-env";
    directory = currentDir + "/.julia_pkgs";
    ##julia_1.5.1
    NUM_THREADS = 12;
    extraPackages = p: with p;[   # GZip.jl # Required by DataFrames.jl
      gzip
      zlib
      libgit2
    ];
  };

  iNix = jupyter.kernels.iNixKernel {
    name = "nix-kernel";
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels= [ iPython iHaskell IRkernel iJulia iNix ];
      directory = jupyter.mkDirectoryWith {
        extensions = [
          "@jupyter-widgets/jupyterlab-manager@2.0"
          "@bokeh/jupyter_bokeh@2.0.0"
          #"@jupyterlab/git@0.21.0-alpha.0"
          "@krassowski/jupyterlab-lsp@1.1.2"
        ];
      };
      extraPackages = p: with p;[ python3Packages.jupyter_lsp python3Packages.python-language-server ];
      extraJupyterPath = p: "${p.python3Packages.jupyter_lsp}/lib/python3.7/site-packages:${p.python3Packages.python-language-server}/lib/python3.7/site-packages";
    };

in
pkgs.mkShell rec {
  name = "Jupyter-data-Env";
  buildInputs = [ jupyterEnvironment
                  pkgs.python3Packages.ipywidgets
                  pkgs.python3Packages.python-language-server
                  pkgs.python3Packages.jupyter_lsp
                  iJulia.runtimePackages
                ];

  shellHook = ''
      export R_LIBS_SITE=${builtins.readFile env.r-libs-site}
      export PATH="${pkgs.lib.makeBinPath ([ env.r-bin-path ] )}:$PATH"
      export PYTHON=python-Python-data-env
      #julia_wrapped -e 'Pkg.add(url="https://github.com/JuliaPy/PyCall.jl")'

     ${pkgs.python3Packages.jupyter_core}/bin/jupyter nbextension install --py widgetsnbextension --user
     ${pkgs.python3Packages.jupyter_core}/bin/jupyter nbextension enable --py widgetsnbextension
    #${jupyterEnvironment}/bin/jupyter-lab --ip
    '';
}
