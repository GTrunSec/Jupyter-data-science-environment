{ stdenv
, python3Packages
, python3
, fetchFromGitHub
}:
with python3.pkgs;
let
  metakernel = python3Packages.buildPythonPackage rec {
    pname = "metakernel";
    version = "0.27.5";
    src = python3Packages.fetchPypi {
      inherit pname version;
      sha256 = "sha256-/htgOskG9hDrxwhqpdnGh2xqskUAiD2e7vNAQ+NPGCs=";
    };
    doCheck = false;
    propagatedBuildInputs = with python3Packages; [ pexpect ipykernel ];
  };
in
python3Packages.buildPythonPackage rec {
  doCheck = false;
  pname = "sas_kernel";
  version = "release";
  src = fetchFromGitHub {
    owner = "sassoftware";
    repo = "sas_kernel";
    rev = "8ea86ded44729c77905231c1c930fd64a32deb48";
    sha256 = "sha256-6G5Z8cbv0osAMSdnc4/WEgIdNry1PopiuqYIc8MQKCQ=";
  };

  propagatedBuildInputs = with python3Packages; [ ipython ipykernel metakernel saspy ];
  preBuild = ''
  mkdir -p $out/local
  '';
  postPatch = ''
  substituteInPlace sas_kernel/install.py \
    --replace "install_my_kernel_spec(user=user, prefix=prefix)" "install_my_kernel_spec(user=user, prefix='$out/local')"
       '';
}
