final: prev:
let
  rev = (builtins.fromJSON (builtins.readFile ../flake.lock)).nodes.julia_15.locked.rev;
  juliaPkg = import (builtins.fetchTarball {
    url    = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
    sha256 = (builtins.fromJSON (builtins.readFile ../flake.lock)).nodes.julia_15.locked.narHash;
  }) {};
in
{
  julia_13 = juliaPkg.julia_15;
  evcxr = juliaPkg.evcxr;
}
