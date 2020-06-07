self: super:
{
  R = super.R.overrideAttrs(oldAttrs: {
    lapack = super.lapack.override {
      lapackProvider = super.openblas;
    };
    blas = super.blas.override {
      blasProvider = super.openblas;
    };
  });
}
