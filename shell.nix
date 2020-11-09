{ pkgs ? import <nixpkgs> {}
, nixpkgs-hardenedlinux
, jupyterWith
}:
let
  jupyter = import jupyterWith { inherit pkgs;};

  iPython = jupyter.kernels.iPythonWith {
    python3 = pkgs.callPackage ./overlays/python-self-packages.nix { inherit pkgs;};
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

  jupyterEnvironment =
    jupyter.jupyterlabWith {
      kernels = [ iPython ];
      directory = jupyter.mkDirectoryWith {
        extensions = [
          "@jupyter-widgets/jupyterlab-manager@2.0"
        ];
      };
    };
  voila = pkgs.writeScriptBin "voila" ''
    nix-shell ${nixpkgs-hardenedlinux}/pkgs/python/env/voila --command "voila"
  '';
in
pkgs.mkShell rec {
  buildInputs = [
    voila
  ];
}
