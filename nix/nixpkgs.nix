let
  src = builtins.fetchTarball {
    url = "https://github.com/GTrunSec/nixpkgs/archive/3fac6bbcf173596dbd2707fe402ab6f65469236e.tar.gz";
    sha256 = "1b3dgc6dwh9fk05fngwszib2zbil7nkbn4kmf2nxn76dc8dvhr3z";
  };
in
  import src
