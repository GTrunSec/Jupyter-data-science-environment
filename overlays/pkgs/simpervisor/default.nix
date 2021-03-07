{ stdenv
, python3Packages
, python3
}:
with python3.pkgs;

python3Packages.buildPythonPackage rec {
  pname = "simpervisor";
  version = "0.4";
  src = python3Packages.fetchPypi {
    inherit pname version;
    sha256 = "sha256-zseeE829btsEpcmMH/jUvZcT5wbAaSJpCaHvDonTk8U=";
  };
  doCheck = false;
  propagatedBuildInputs = with python3Packages; [ ];

}
