{ stdenv
, python3Packages
, python3
, fetchFromGitHub
}:
with python3.pkgs;

python3Packages.buildPythonPackage rec {
  doCheck = false;
  pname = "saspy";
  version = "3.6.2";
  src = fetchFromGitHub {
    owner = "sassoftware";
    repo = "saspy";
    rev = "c4c7a960b61d3110ea1082eb53e0107a7086ca2c";
    sha256 = "sha256-TCqt6ecKCpiR8N+c9EQmM7PdXQyDRHLooudCHpkeGZE=";
  };

  propagatedBuildInputs = with python3Packages; [
    setuptools
  ];
}
