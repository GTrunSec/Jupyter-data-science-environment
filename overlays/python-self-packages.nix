{ python3, pkgs }:
let
    my-overlay = pkgs.fetchFromGitHub {
    owner = "hardenedlinux";
    repo = "nixpkgs-hardenedlinux";
    rev = "bd99eb5e9a3f1c6d43d49f4873457ecc5ecf9440";
    sha256 = "193vp43xwsxdpzq8hyi5bq8hixmni6vj1ya7dn80cf7ymix13qyl";
    };

in
python3.override {
  packageOverrides = self: super: rec {
    editdistance =  self.callPackage "${my-overlay}/pkgs/python/editdistance" {};
    mlfinlab =  self.callPackage ./pkgs/mlfinlab {};
    pyfolio =  self.callPackage ./pkgs/pyfolio {};
    nbdev =  self.callPackage ./pkgs/nbdev {};
    zat =  self.callPackage "${my-overlay}/pkgs/python/zat" {};
    fastai = self.callPackage "${my-overlay}/pkgs/python/fast-ai" {};
    fastai2 = self.callPackage "${my-overlay}/pkgs/python/fastai2" {};
  };
}
