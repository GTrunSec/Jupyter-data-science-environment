let
  inherit (inputflake) loadInput flakeLock;
  inputflake = import ./nix/lib.nix {};
  jupyterLib = import <jupyterLib>;
  env = (import (<jupyterLib> + "/lib/directory.nix")){ inherit pkgs Rpackages;};
  overlays = [
    # Only necessary for Haskell kernel
    (import ./overlays/python-overlay.nix)
    (import ./overlays/package-overlay.nix)
    (import ./overlays/haskell-overlay.nix)
    (import ./overlays/julia-overlay.nix)
    (import (<nixpkgs-hardenedlinux> + "/nix/python-packages-overlay.nix"))
  ];

  pkgs = import <nixpkgs> { inherit overlays; config={ allowUnfree=true; allowBroken=true;};};

  jupyter = import <jupyterLib> {pkgs=pkgs;};


  iPython = jupyter.kernels.iPythonWith {
    name = "Python-kernel";
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
    name = "IRkernel";
    packages = import ./overlays/R-packages-list.nix {inherit pkgs;};
  };

  Rpackages = p: with p; [ ggplot2 ];

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "haskell";
    packages = import ./overlays/haskell-packages-list.nix { inherit pkgs;
                                                             Diagrams = true; Hasktorch = true; InlineC = true; Matrix = true;
                                                           };
    r-libs-site = env.r-libs-site;
    r-bin-path = env.r-bin-path;
  };

  iNix = jupyter.kernels.iNixKernel {
    name = "nix-kernel";
  };

  iRust = jupyter.kernels.rustWith {
    name = "data-rust-env";
  };

  CXX = jupyter.kernels.xeusCling {
    name = "cxx-kernel";
  };

  iJulia = jupyter.kernels.iJuliaWith {
    name =  "Julia-data-env";
    directory = "./julia-pkgs";
    NUM_THREADS = 24;
    cuda = true;
    cudaVersion = pkgs.cudatoolkit_10_2;
    nvidiaVersion = pkgs.linuxPackages.nvidia_x11;
    extraPackages = p: with p;[   # GZip.jl # Required by DataFrames.jl
      gzip
      zlib
    ];
  };

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython iHaskell IRkernel iJulia iNix iRust ];
    };
in
{
  Jupyter-data-science-environment = pkgs.buildEnv {
    name = "Jupyter-data-science-environment";
    paths = [ jupyterEnvironment
              iJulia.runtimePackages
            ];
  };
}
