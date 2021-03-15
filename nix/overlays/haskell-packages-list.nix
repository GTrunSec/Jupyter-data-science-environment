{ pkgs
, Diagrams ? false
, InlineR ? false
, Hasktorch ? false
, Matrix ? false
}:
(with pkgs.haskellPackages.ghcWithPackages; (p: with p;  [
  #monad-bayes
  hvega
  formatting
  hvega
  statistics
  vector
  aeson
  aeson-pretty
  formatting
  foldl
  hlint
  histogram-fill
  # #funflow
  JuicyPixels
  lens
  #random-fu failure with 884
] ++ pkgs.lib.optionals Diagrams [
  diagrams
  Chart
] ++ pkgs.lib.optionals InlineR [
  # ihaskell-diagrams
  # ihaskell-hvega
  # ihaskell-blaze
  # ihaskell-charts
  # inline-r
] ++ pkgs.lib.optionals Hasktorch [
  # libtorch-ffi_cpu
  # hasktorch-examples_cpu
  #hasktorch_cpu
] ++ pkgs.lib.optionals Matrix [
  matrix
  hmatrix
]
))
