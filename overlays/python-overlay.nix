_: pkgs:
let
  packageOverrides = selfPythonPackages: pythonPackages: {
    jupyterlab_git =  pkgs.callPackage ./pkgs/jupyterlab-git {};
    jupyter_lsp =  pkgs.callPackage ./pkgs/jupyter-lsp {};
    jupytext =  pkgs.callPackage ./pkgs/jupytext {};

    pyzmq = pythonPackages.pyzmq.overridePythonAttrs (_:{
      src = pythonPackages.fetchPypi {
        pname = "pyzmq";
        version = "20.0.0";
        sha256 = "sha256-gkrViIMxqt6sdyvOJ+HC+8q4L63pLtvSNFQsThLw3Kk=";
      };
    });

    ipykernel = pythonPackages.ipykernel.overridePythonAttrs (_:{
      src = pythonPackages.fetchPypi {
        pname = "ipykernel";
        version = "5.3.4";
        sha256 = "sha256-myZSrxYHmGobIxxiMC0HC8BTT1ZMOTpdnRMNuau76J0=";
      };
    });

    fsspec = pythonPackages.fsspec.overridePythonAttrs (_:{
      src = pkgs.fetchFromGitHub {
        owner = "intake";
        repo = "filesystem_spec";
        rev =  "0.8.4";
        sha256 = "sha256-3Xk/vaQRy9iV52IFo26CmSuRo4uzm9cH7iOtaocr/Ks=";
      };
    });
    # jupyterlab = pythonPackages.jupyterlab.overridePythonAttrs (_:{
    #   src = pythonPackages.fetchPypi {
    #     pname = "jupyterlab";
    #     version = "3.0.0a10";
    #     sha256 = "sha256-xUPFeRXnjf6gzZJ3/ro0d7ULjjwS2cyYW9sOrWqDgWI=";
    #   };
    #   propagatedBuildInputs = [
    #     (let
    #       jupyterlab_server =  pkgs.callPackage ./pkgs/jupyterlab_server {};
    #     in
    #       jupyterlab_server
    #     )
    #     (let
    #       nbclassic =  pkgs.callPackage ./pkgs/nbclassic {};
    #     in
    #       nbclassic
    #     )
    #     pythonPackages.notebook
    #   ];
    # });


    jupyter_contrib_core = pythonPackages.buildPythonPackage rec {
      pname = "jupyter_contrib_core";
      version = "0.3.3";

      src = pythonPackages.fetchPypi {
        inherit pname version;
        sha256 = "e65bc0e932ff31801003cef160a4665f2812efe26a53801925a634735e9a5794";
      };
      doCheck = false;  # too much
      propagatedBuildInputs = [
        pythonPackages.traitlets
        pythonPackages.notebook
        pythonPackages.tornado
      ];
    };

    jupyter_nbextensions_configurator = pythonPackages.buildPythonPackage rec {
      pname = "jupyter_nbextensions_configurator";
      version = "0.4.1";

      src = pythonPackages.fetchPypi {
        inherit pname version;
        sha256 = "e5e86b5d9d898e1ffb30ebb08e4ad8696999f798fef3ff3262d7b999076e4e83";
      };

      propagatedBuildInputs = [
        selfPythonPackages.jupyter_contrib_core
        pythonPackages.pyyaml
      ];

      doCheck = false;  # too much
    };

    jupyter_c_kernel = pythonPackages.buildPythonPackage rec {
      pname = "jupyter_c_kernel";
      version = "1.2.2";
      doCheck = false;

      src = pythonPackages.fetchPypi {
        inherit pname version;
        sha256 = "e4b34235b42761cfc3ff08386675b2362e5a97fb926c135eee782661db08a140";
      };

      meta = with pkgs.stdenv.lib; {
        description = "Minimalistic C kernel for Jupyter";
        homepage = https://github.com/brendanrius/jupyter-c-kernel/;
        license = licenses.mit;
        maintainers = [];
      };
    };
  };
in

{
  python3 = pkgs.python3.override (old: {
    packageOverrides =
      pkgs.lib.composeExtensions
        (old.packageOverrides or (_: _: {}))
        packageOverrides;
  });
}
