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

  extraLibs = with pkgs;[
    mbedtls
    zeromq3
    # ImageMagick.jl
    imagemagickBig
    # HDF5.jl
    hdf5
    # Cairo.jl
    cairo
    gettext
    pango.out
    glib.out
    # Gtk.jl
    gtk3
    gdk_pixbuf
    # GZip.jl # Required by DataFrames.jl
    gzip
    zlib
    # GR.jl # Runs even without Xrender and Xext, but cannot save files, so those are required
    xorg.libXt
    xorg.libX11
    xorg.libXrender
    xorg.libXext
    glfw
    freetype
    # Flux.jl
    git gitRepo gnupg autoconf curl
    procps gnumake utillinux m4 gperf unzip
    #libGLU_combined
    xorg.libXi xorg.libXmu freeglut
    xorg.libXext xorg.libX11 xorg.libXv xorg.libXrandr zlib
    ncurses5 stdenv.cc binutils
    # Arpack.jl
    arpack
    gfortran.cc
  ];
in mkShell {
  name = "julia";
  buildInputs = [ juliaEnv ];
  shellHook = ''
  export JULIA_PKGDIR=$(realpath ./.julia_pkgs)
  export JULIA_DEPOT_PATH=$(realpath ./.julia_pkgs)
  export JULIA_NUM_THREADS=8
  echo "Update Julia packages"
   ${juliaEnv}/bin/julia -e 'using Pkg; Pkg.add("IJulia")' \
   && ${juliaEnv}/bin/julia -e 'using Pkg; Pkg.add("Flux"); using Flux' \
   && ${juliaEnv}/bin/julia -e 'using IJulia; installkernel("Julia_8_threads", env=Dict("JULIA_DEPOT_PATH"=>"${pwd_dir}/.julia_pkgs","JULIA_PKGDIR"=>"${pwd_dir}/.julia_pkgs","JULIA_NUM_THREADS"=>"8","LD_LIBRARY_PATH"=>"${pkgs.lib.makeLibraryPath extraLibs}"))'
  '';
}
