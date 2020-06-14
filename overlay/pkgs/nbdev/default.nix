{ stdenv
, python3Packages
, python3
, fetchurl
}:
with python3.pkgs;
let
  fastscript = python3Packages.buildPythonPackage rec {
    doCheck = false;
    pname = "fastscript";
    version = "0.1.5";
    src = fetchurl {
      url = "https://github.com/fastai/fastscript/archive/c217e613824c5219a1035faf9b8f0b11ae64c067.tar.gz";
      sha256 = "0cf64225jsalqg5b8hzjrj5c3fbdia0x3gzj85kww91iskhg3y8n";
    };

    propagatedBuildInputs = with python3Packages; [
      packaging
      setuptools
      pyyaml
    ];
  };
in
python3Packages.buildPythonPackage rec {
      pname = "nbdev";
      version = "0.2.18";
      doCheck = false;

      src = pythonPackages.fetchPypi {
        inherit pname version;
        sha256 = "1ya9q3b3fya03hhqi3y5cipcr534xky47n3y2y6rzv5xay0ipy6j";
      };
      propagatedBuildInputs = with python3Packages; [ notebook
                                                      fastscript
                                                    ];
}
