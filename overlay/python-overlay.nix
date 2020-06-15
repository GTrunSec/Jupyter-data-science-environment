_: pkgs:
let
  packageOverrides = selfPythonPackages: pythonPackages: {

    jupyterlab_git =  pkgs.callPackage ./pkgs/jupyterlab-git {};
    jupyter_lsp =  pkgs.callPackage ./pkgs/jupyter-lsp {};

    jupyterlab = pythonPackages.jupyterlab.overridePythonAttrs (_:{
      src = pythonPackages.fetchPypi {
        pname = "jupyterlab";
        version = "2.1.2";
        sha256 = "015iyhc877sc3npjn8mnpfvzxd1vh73k8lv1h3izip7nfkb2j31q";
      };
      propagatedBuildInputs = [
        (pythonPackages.jupyterlab_server.overridePythonAttrs (_:{
          src = pythonPackages.fetchPypi {
            pname = "jupyterlab_server";
            version = "1.1.0";
            sha256 = "0cqpyy4jr3023c47ij08djkpx526gmz8fab45mcnws0glhp7xhms";
          };
        }))
        pythonPackages.notebook];
    });


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