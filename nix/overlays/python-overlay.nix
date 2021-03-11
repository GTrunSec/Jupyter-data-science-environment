_: pkgs:
let
  inputflake = import ../lib.nix { };
  inherit (inputflake) loadInput flakeLock;
  mach-nix = (import (loadInput flakeLock.mach-nix)) {
    pypiDataRev = "2205d5a0fc9b691e7190d18ba164a3c594570a4b";
    pypiDataSha256 = "1aaylax7jlwsphyz3p73790qbrmva3mzm56yf5pbd8hbkaavcp9g";
  };
  python-custom = mach-nix.mkPython rec {
    requirements = builtins.readFile ../python-environment.txt;
  };

  packageOverrides = selfPythonPackages: pythonPackages: {

    dask = (if pkgs.python.passthru.pythonVersion > "3.8" then
      pythonPackages.dask.overridePythonAttrs
        (_: {
          src = pythonPackages.fetchPypi {
            pname = "dask";
            version = "2.30.0";
            sha256 = "sha256-oWaQIuJd6ZsifD2D2kgB8DJBWWLaxDEJm/BTRkjkGlQ=";
          };
        }) else pythonPackages.dask.overridePythonAttrs (_: { }));

    pyzmq = (if pkgs.python.passthru.pythonVersion > "3.8" then
      pythonPackages.pyzmq.overridePythonAttrs
        (_: {
          src = pythonPackages.fetchPypi {
            pname = "pyzmq";
            version = "20.0.0";
            sha256 = "sha256-gkrViIMxqt6sdyvOJ+HC+8q4L63pLtvSNFQsThLw3Kk=";
          };
        }) else pythonPackages.pyzmq.overridePythonAttrs (_: { }));

    ipykernel = (if pkgs.python.passthru.pythonVersion > "3.8" then
      pythonPackages.ipykernel.overridePythonAttrs
        (_: {
          src = pythonPackages.fetchPypi {
            pname = "ipykernel";
            version = "5.3.4";
            sha256 = "sha256-myZSrxYHmGobIxxiMC0HC8BTT1ZMOTpdnRMNuau76J0=";
          };
        }) else pythonPackages.ipykernel.overridePythonAttrs (_: { }));

    fsspec = (if pkgs.python.pythonVersion > "3.8" then
      pythonPackages.fsspec.overridePythonAttrs
        (_: {
          src = pkgs.fetchFromGitHub {
            owner = "intake";
            repo = "filesystem_spec";
            rev = "0.8.4";
            sha256 = "sha256-3Xk/vaQRy9iV52IFo26CmSuRo4uzm9cH7iOtaocr/Ks=";
          };
        }) else pythonPackages.fsspec.overridePythonAttrs (_: { }));

    jupyter_contrib_core = pythonPackages.buildPythonPackage rec {
      pname = "jupyter_contrib_core";
      version = "0.3.3";

      src = pythonPackages.fetchPypi {
        inherit pname version;
        sha256 = "e65bc0e932ff31801003cef160a4665f2812efe26a53801925a634735e9a5794";
      };
      doCheck = false; # too much
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

      doCheck = false; # too much
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
        maintainers = [ ];
      };
    };
  };
in
{
  python3 = pkgs.python3.override (old: {
    packageOverrides =
      pkgs.lib.composeExtensions
        (old.packageOverrides or (_: _: { }))
        packageOverrides;
  });
}
