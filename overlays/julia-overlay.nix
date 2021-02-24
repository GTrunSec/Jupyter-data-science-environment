final: prev:
let
  inputflake = import ../nix/lib.nix { };
  inherit (inputflake) loadInput flakeLock;
  juliaPkg = (import (loadInput flakeLock.julia_15)) { };
in
{
  julia_13 = juliaPkg.julia_15;
  evcxr = juliaPkg.evcxr;
}
