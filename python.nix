{ python3, pkgs }:
let
my-overlay = pkgs.fetchFromGitHub {
    owner = "GTrunSec";
    repo = "nixpkgs-overlays";
    rev = "ba257528be9850df04a7dba6e9e4d7988beecd0b";
    sha256 = "0rfm4zjys5b1mbqf8wy1n31ir0hdzi79p8i2cnh23f17pghjlrh9";
  };
in
python3.override {
  packageOverrides = self: super: rec {
    editdistance =  self.callPackage "${my-overlay}/python/editdistance" {};
  };
}
