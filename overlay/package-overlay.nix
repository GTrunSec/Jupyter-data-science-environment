self: super:
{
  R = super.R.override {
    blas = super.blas.override {
      blasProvider = super.lapack-reference;
    };
  };  
}
