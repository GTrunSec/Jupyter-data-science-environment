{ pkgs ? import <nixpkgs> {} }:

with pkgs;
let
  my-pkgs = pkgs.fetchFromGitHub {
    owner = "hardenedlinux";
    repo = "NSM-data-analysis";
    rev = "1bc6bc22c63c034d272150a26d74b149cc677ab8";
    sha256 = "18yrwg6xyhwmf02l6j7rcmqyckfqg0xy3nx4lcf6lbhc16mfncnf";
  };

  juliaEnv = (import "${my-pkgs}/pkgs/julia-non-cuda.nix" {});
  pwd_dir = builtins.getEnv "PWD";
in

mkShell {
  name = "julia";
  buildInputs = [ juliaEnv ];
  shellHook = ''
  export JULIA_PKGDIR=$(realpath ./.julia_pkgs)
  export JULIA_DEPOT_PATH=$(realpath ./.julia_pkgs)
  export JULIA_NUM_THREADS=8
  echo "Update Julia packages"
   ${juliaEnv}/bin/julia -e 'using Pkg; Pkg.add("IJulia")' \
   && ${juliaEnv}/bin/julia -e 'using Pkg; Pkg.add("Flux"); using Flux' \
   && ${juliaEnv}/bin/julia -e 'using Pkg; using Flux'\
   && ${juliaEnv}/bin/julia -e 'using IJulia; installkernel("Julia_8_threads", env=Dict("JULIA_DEPOT_PATH"=>"${pwd_dir}/.julia_pkgs","JULIA_PKGDIR"=>"${pwd_dir}/.julia_pkgs","JULIA_NUM_THREADS"=>"8"))'
  '';
}
