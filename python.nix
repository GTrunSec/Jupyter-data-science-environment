{ python3 }:

python3.override {
  packageOverrides = self: super: rec {
    editdistance =  self.callPackage ../NSM-data-analysis/pkgs/python/editdistance {};
  };
}
