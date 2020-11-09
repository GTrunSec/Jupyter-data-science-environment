{ stdenv
, python3Packages
, python3
}:
with python3.pkgs;

let
  nbdime = python3Packages.buildPythonPackage rec {
    pname = "nbdime";
    version = "2.0.0";
    disabled = !isPy3k;

    src = fetchPypi {
      inherit pname version;
      sha256 = "0pbi22mc5al29pvsw7bhai2d58i8n77gv09r7avr1wap6ni7jvw9";
    };

    doCheck = false;
    propagatedBuildInputs = with python3Packages; [
      hypothesis
      pytestcov
      pytest-timeout
      pytest-tornado
      jsonschema
      mock
      tabulate
      pytest
      setuptools_scm
      attrs
      py
      setuptools
      six
      nbformat
      colorama
      pygments
      tornado
      requests
      GitPython
      notebook
      jinja2
    ];
  };

in
python3Packages.buildPythonPackage rec {
      pname = "jupyterlab_git";
      version = "0.20.0";
      doCheck = false;

      src = pythonPackages.fetchPypi {
        inherit pname version;
        sha256 = "0qs3wrcils07xlz698xr7giqf9v63n2qb338mlh7wql93rmjg45i";
      };
      propagatedBuildInputs = with python3Packages; [ notebook
                                                      nbdime
                                                    ];
}
