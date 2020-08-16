{ stdenv
, python3Packages
, python3
, callPackage
, fetchurl
}:
with python3.pkgs;

python3Packages.buildPythonPackage rec {
  pname = "nbclassic";
  version = "0.2.0rc4";
  doCheck = false;

  src = fetchurl {
    url = "https://github.com/Zsailer/nbclassic/archive/49073a2cd96a39b13dee85047513530da88d87f3.tar.gz";
    sha256 = "sha256-cBFEkicVfcZxWD3RTaLgWHu1gR+qZ2O4hJrbXLZNDw8=";
  };
  propagatedBuildInputs = with python3Packages; [
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
    notebook
  ];
}
