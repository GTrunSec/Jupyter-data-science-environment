{ python3, pkgs }:
let
  my-overlay  = builtins.fetchGit {
    url = "https://github.com/hardenedlinux/NSM-data-analysis";
    rev = "07a94f1f8a154e0aa4e9f9675014d663e91a73de";
  };

in
python3.override {
  packageOverrides = self: super: rec {
    editdistance =  self.callPackage "${my-overlay}/pkgs/python/editdistance" {};
    jupyterlab_git =  self.callPackage ./pkgs/jupyterlab-git {};
  };
}
