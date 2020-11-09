{ stdenv
, python3Packages
, python3
}:
with python3.pkgs;
let
  empyrical = python3Packages.buildPythonPackage rec {
    doCheck = false;
    pname = "empyrical";
    version = "0.5.3";
    src = fetchPypi {
      inherit pname version;
      sha256 = "0pdvwag1a7r71c44pranl4wjrqbk1p6cfpfddh9mn6v9gx0ija4f";
    };

    propagatedBuildInputs = with python3Packages; [
      scipy
      pandas
      numpy
      (python3Packages.buildPythonPackage rec {
        doCheck = false;
        pname = "pandas-datareader";
        version = "0.8.1";
        src = fetchPypi {
          inherit pname version;
          sha256 = "14kskislpv1psk8c2xz4qik4n228iiz6fmxcw41y3dc4dhb6nxmq";
        };
        propagatedBuildInputs = with python3Packages; [pandas
                                                       requests
                                                       lxml
                                                      ];
      })
    ];
  };

in
python3Packages.buildPythonPackage rec {
  pname = "pyfolio";
  version = "0.9.2";
  doCheck = false;

  src = pythonPackages.fetchPypi {
    inherit pname version;
    sha256 = "1ad2ybsqkajz5f41chjvb87q3i8vy7shca7gryn8jjq306dkxrka";
  };
  propagatedBuildInputs = with python3Packages; [
    ipython
    matplotlib
    numpy
    pandas
    pytz
    scipy
    scikitlearn
    seaborn
    empyrical 
  ];
}
