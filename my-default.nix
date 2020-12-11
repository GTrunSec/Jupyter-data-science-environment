let
  inherit (inputflake) loadInput flakeLock;
  inputflake = import ./nix/lib.nix {};
  pkgs = (import (loadInput flakeLock.nixpkgs)) { inherit overlays; config={ allowUnfree=true; allowBroken=true; };};
  #pkgs = (import (loadInput flakeLock.python37)) { inherit overlays; config={ allowUnfree=true; allowBroken=true; };};
  jupyter = (import (loadInput flakeLock.jupyterWith)){ inherit pkgs;};
  #jupyter = (import ../jupyterWith){ inherit pkgs;};
  env = (import ((loadInput flakeLock.jupyterWith) + "/lib/directory.nix")){ inherit pkgs Rpackages;};

  overlays = [
    # Only necessary for Haskell kernel
    (import ./overlays/python-overlay.nix)
    (import ./overlays/package-overlay.nix)
    (import ./overlays/julia-overlay.nix)
    (import ./overlays/haskell-overlay.nix)
    (import ((loadInput flakeLock.nixpkgs-hardenedlinux) + "/nix/python-packages-overlay.nix"))
  ];


  Rpackages = p: with p; [ ggplot2 dplyr xts purrr cmaes cubature
                           reshape2
                         ];

  iPython = jupyter.kernels.iPythonWith {
    name = "Python-data-env";
    packages = import ./overlays/python-packages-list.nix { inherit pkgs;
                                                            MachineLearning = true;
                                                            DataScience = true;
                                                            Financial = true;
                                                            Graph =  true;
                                                            SecurityAnalysis = true;
                                                            Sas = true;
                                                          };
    ignoreCollisions = true;
  };

  IRkernel = jupyter.kernels.iRWith {
    name = "IRkernel-data-env";
    packages = import ./overlays/R-packages-list.nix { inherit pkgs;};
  };

  iHaskell = jupyter.kernels.iHaskellWith {
    name = "ihaskell-data-env";
    extraIHaskellFlags = "--codemirror Haskell";  # for jupyterlab syntax highlighting
    packages = import ./overlays/haskell-packages-list.nix { inherit pkgs;
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
    extraEnv = {
      PYTHON = "${toString iPython.kernelEnv}/bin/python";
      PYTHONPATH = "${toString iPython.kernelEnv}/${pkgs.python3.sitePackages}";
    };
    nvidiaVersion = pkgs.linuxPackages.nvidia_x11;
    extraPackages = p: with p;[
      # GZip
      # gzip
      # zlib
    ];
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
      kernels = [ iPython iHaskell IRkernel iJulia iNix iRust CXX ];
      directory = jupyter.mkDirectoryWith {
        extensions = [
          "@jupyter-widgets/jupyterlab-manager@2.0.0"
          "jupyterlab-jupytext"
        ];
      };
      extraPackages = p: with p;[ python3Packages.jupytext pkgs.pandoc ];
      extraJupyterPath = p: "${p.python3Packages.jupytext}/${p.python3.sitePackages}";
    };


  sasFix = pkgs.runCommand "fix-script" { } ''
    mkdir -p $out/share
    cp -r ${pkgs.python3Packages.sas_kernel}/local/share/jupyter/kernels/sas/* $out/share
    substituteInPlace $out/share/kernel.json \
          --replace "${toString pkgs.python3}/bin/${toString pkgs.python3.executable}" "${toString iPython.runtimePackages}/bin/python-Python-data-env"
  '';
in
pkgs.mkShell rec {
  name = "Jupyter-data-Env";
  buildInputs = [ jupyterEnvironment
                  pkgs.python3Packages.jupytext
                  iJulia.runtimePackages
                  iPython.runtimePackages
                  IRkernel.runtimePackages
                  CXX.runtimePackages
                  pkgs.pandoc
                ];
  
  shellHook = ''
      # export R_LIBS_SITE=${builtins.readFile env.r-libs-site}
      # export PATH="${pkgs.lib.makeBinPath ([ env.r-bin-path ] )}:$PATH"
      #Pycall
      export PYTHON="${toString iPython.kernelEnv}/bin/python"
      export PYTHONPATH="${toString iPython.kernelEnv}/${pkgs.python3.sitePackages}"
      #julia_wrapped -e 'Pkg.add(url="https://github.com/JuliaPy/PyCall.jl")'
      ln -sfT ${toString sasFix}/share ~/.local/share/jupyter/kernels/sas-kernel-env
    #for emacs-ein to load kernels environment.
      ln -sfT ${iPython.spec}/kernels/ipython_Python-data-env ~/.local/share/jupyter/kernels/ipython_Python-data-env
      ln -sfT ${iHaskell.spec}/kernels/ihaskell_ihaskell-data-env ~/.local/share/jupyter/kernels/iHaskell-data-env
      ln -sfT ${iJulia.spec}/kernels/julia_Julia-data-env ~/.local/share/jupyter/kernels/iJulia-data-env
      ln -sfT ${IRkernel.spec}/kernels/ir_IRkernel-data-env ~/.local/share/jupyter/kernels/IRkernel-data-env
      ln -sfT ${iNix.spec}/kernels/inix_nix-kernel/  ~/.local/share/jupyter/kernels/INix-data-env
      ln -sfT ${iRust.spec}/kernels/rust_data-rust-env  ~/.local/share/jupyter/kernels/IRust-data-env
    #${jupyterEnvironment}/bin/jupyter-lab
    '';
}
