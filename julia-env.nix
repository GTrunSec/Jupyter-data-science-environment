{ pkgs ? import <nixpkgs> {} }:

with pkgs;
let
  my-pkgs = pkgs.fetchFromGitHub {
    owner = "hardenedlinux";
    repo = "NSM-data-analysis";
    rev = "1bc6bc22c63c034d272150a26d74b149cc677ab8";
    sha256 = "18yrwg6xyhwmf02l6j7rcmqyckfqg0xy3nx4lcf6lbhc16mfncnf";
  };

  julia = (import "${my-pkgs}/pkgs/julia-non-cuda.nix" {});

in

mkShell {
  name = "julia";
  buildInputs = [ julia ];
  shellHook = ''
  echo "Update Julia packages"
  julia -e 'using Pkg; Pkg.update()' \
  && julia -e 'using Pkg; Pkg.add("IJulia")' \
  && julia -e 'using IJulia; installkernel"Julia_8_threads", env=Dict("JULIA_NUM_THREADS"=>"8"))'
  '';
}
