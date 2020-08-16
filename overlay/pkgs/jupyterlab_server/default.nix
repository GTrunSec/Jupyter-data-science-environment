{ stdenv
, python3Packages
, python3
}:
with python3.pkgs;

let
  babel = python3Packages.buildPythonPackage rec {
    pname = "Babel";
    version = "2.8.0";

    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-Gqwq4tDY6jaPqQkGVn9cCEY9mK3hVcDEv+3WoPcWDjg=";
    };

    doCheck = false;
    propagatedBuildInputs = with python3Packages; [
      pytz
      (let
          jupyter_server = python3Packages.buildPythonPackage rec {
            pname = "jupyter_server";
            version = "1.0.0rc5";

            src = fetchPypi {
              inherit pname version;
              sha256 = "sha256-+NgR9c4E5Ln0dqgvV1izY0Ws9HpSa4F5j4ajnVIMzYE=";
            };
            propagatedBuildInputs = with python3Packages; [
              nbformat
              tornado
              jinja2
              prometheus_client
              jupyter_client
              jupyter_core
              nbconvert
              send2trash
              terminado
              packaging
            ];
            doCheck = false;
          };
      in
        jupyter_server
      )
    ];
  };

in
python3Packages.buildPythonPackage rec {
  doCheck = false;
  pname = "jupyterlab_server";
  version = "2.0.0b1";
  src = pythonPackages.fetchPypi {
    inherit pname version;
    sha256 = "sha256-xFJ0kmgvOo+EkqkA6wMkVCBq5StVsLQDnxkeQvwpVOQ=";
  };
  propagatedBuildInputs = [ notebook jsonschema pyjson5 babel ];
}
