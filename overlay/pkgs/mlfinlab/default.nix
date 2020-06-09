{ stdenv
, python3Packages
, python3
, fetchgit
}:
with python3.pkgs;
let
  xmlrunner = python3Packages.buildPythonPackage rec {
    pname = "xmlrunner";
    version = "1.7.7";
    doCheck = false;

    src = fetchPypi {
      inherit pname version;
      sha256 = "0f8g27bicbkpw0zficnfnnqbynvfjrk74rgf25hn99zc97816qas";
    };

    doInstallCheck = false;
    propagatedBuildInputs = with python3Packages; [
      six
    ];
  };
in
python3Packages.buildPythonPackage rec {
  pname = "mlfinlab";
  version = "0.11.3";
  doCheck = false;

  src = fetchgit {
    url = "https://github.com/hudson-and-thames/mlfinlab.git";
    rev = "665939070e00f6f49c97d6f6f3489ff6bfd46061";
    sha256 = "0ffnscp86iacbqgcsnrkip5xvqhhdwag6az95i2ddhns8b07amki";
  };

  doInstallCheck = false;
  propagatedBuildInputs = with python3Packages; [
    codecov
    coverage
    cvxpy
    numba
    numpy
    matplotlib
    pandas
    pylint
    scikitlearn
    scipy
    sphinx
    sphinx_rtd_theme
    statsmodels
    xmlrunner
  ];

  postPatch = ''
      substituteInPlace setup.cfg \
      --replace "==" ">=" \
      --replace "xmlrunner>=1.7.7" "xmlrunner" \
      --replace "numba>=0.49.1" "numba"
      '';

}
