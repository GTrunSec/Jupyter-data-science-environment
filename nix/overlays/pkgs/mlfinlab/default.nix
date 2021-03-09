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

  POT = python3Packages.buildPythonPackage rec {
    pname = "POT";
    version = "0.7.0";
    doCheck = false;

    src = fetchPypi {
      inherit pname version;
      sha256 = "sha256-1KwryHkfBJoxZoINUeIY1sKZiFRJtzXq/vjRjHbUrQY=";
    };

    doInstallCheck = false;
    propagatedBuildInputs = with python3Packages; [
      cython
      scipy
      autograd
      scikitlearn
      pytest
      cvxopt
      numpy
    ];
  };
in
python3Packages.buildPythonPackage rec {
  pname = "mlfinlab";
  version = "0.11.3";
  doCheck = false;

  src = fetchgit {
    url = "https://github.com/hudson-and-thames/mlfinlab.git";
    rev = "277b447a1db904bd5c46038d4dc3dccdfc13d093";
    sha256 = "sha256-7e/ZBA2wBZXdTH+8Z93+u1wvKvieA49I699vauHB3kw=";
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
    POT
  ];

  postPatch = ''
    substituteInPlace setup.cfg \
    --replace "==" ">=" \
    --replace "xmlrunner>=1.7.7" "xmlrunner" \
    --replace "scikit-learn>=0.23.1" "scikit-learn" \
    --replace "Cython>=0.29.21" "Cython" \
    --replace "cvxpy>=1.1.1" "cvxpy" \
    --replace "pandas>=1.0.4" "pandas" \
    --replace "numpy>=1.18.5" "numpy" \
    --replace "numba>=0.49.1" "numba"
  '';

}
