let
  src = builtins.fetchTarball {
    url = "https://github.com/GTrunSec/nixpkgs/archive/my-release.tar.gz";
    sha256 = "1411z0df803g3pzsh5m1w4652mibwbggsza9y96w9bi7w6hrvswg";
  };
in
  import src
