{ stdenv
, python3Packages
, python3
, fetchurl
}:
with python3.pkgs;
let
  markdown-it-py = python3Packages.buildPythonPackage rec {
    pname = "markdown-it-py";
    version = "0.5.6";
    src = python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-YUPREiFJXtv3G+t+RVghrmyPAVZxChsRgSZi7W29Fls=";
    };
    doCheck = false;
    propagatedBuildInputs = with python3Packages; [ attrs ];
  };
in
python3Packages.buildPythonPackage rec {
  pname = "jupytext";
  version = "1.7.1";
  doCheck = false;

  src = fetchurl {
    url = "https://github.com/mwouts/jupytext/archive/v${version}.tar.gz";
    hash = "sha256-2uc500MvC8phACDNAhMiVLnqNwYmHzuIdh6JUeJXRS4=";
  };
  propagatedBuildInputs = with python3Packages; [
    nbformat
    pyyaml
    toml
    markdown-it-py
  ];
}
