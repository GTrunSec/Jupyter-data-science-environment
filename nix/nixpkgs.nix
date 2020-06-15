let
  src = builtins.fetchTarball {
    url = "https://github.com/GTrunSec/nixpkgs/archive/my-release.tar.gz";
    sha256 = "13hza44bk5fbr9zyrn9iw9z54zrwwnh7a85pxg9lb9anl3y2pxna";
  };
in
  import src
