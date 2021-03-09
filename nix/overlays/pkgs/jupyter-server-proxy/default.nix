{ stdenv
, python3Packages
, python3
, fetchFromGitHub
}:
with python3.pkgs;
let
  jupyter-packaging = python3Packages.buildPythonPackage rec {
    pname = "jupyter-packaging";
    version = "0.7.12";
    src = python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-sUAyV3GIGn33t/LRSZe2GQY/51rnVrkCWFLkNGAAu7g=";
    };
    doCheck = false;
    propagatedBuildInputs = with python3Packages; [ packaging ];
  };

  simpervisor = python3Packages.buildPythonPackage rec {
    pname = "simpervisor";
    version = "0.4";
    src = python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-zseeE829btsEpcmMH/jUvZcT5wbAaSJpCaHvDonTk8U=";
    };
    doCheck = false;
    propagatedBuildInputs = with python3Packages; [ ];
  };
in
python3Packages.buildPythonPackage rec {
  pname = "jupyter-server-proxy";
  version = "1.6.0";
  doCheck = false;
  src = python3Packages.fetchPypi {
    inherit pname version;
    sha256 = "sha256-XgjWaiYrBpEiwCkQL2244wfp0Pr6Bdlaqxq36i33sWk=";
  };
  propagatedBuildInputs = with python3Packages; [
    jupyter-packaging
    simpervisor
    aiohttp
    notebook
  ];
}
