{ pkgs
, Diagrams ? false
, InlineC ? false
, Hasktorch ? false
, Matrix ? false
}:
(with pkgs.haskellPackages.ghcWithPackages; (p: with p;  [ hvega
                                                           formatting
                                                           inline-r
                                                           monad-bayes
                                                           hvega
                                                           statistics
                                                           vector
                                                           aeson
                                                           aeson-pretty
                                                           formatting
                                                           foldl
                                                           hlint
                                                           histogram-fill
                                                           #funflow
                                                           JuicyPixels
                                                           lens
                                                           random-fu
                                                         ] ++ pkgs.lib.optionals Diagrams [
                                                           diagrams
                                                           Chart
                                                           ihaskell-diagrams
                                                           ihaskell-hvega
                                                           ihaskell-blaze
                                                           ihaskell-charts
                                                         ] ++ pkgs.lib.optionals InlineC [
                                                           inline-c
                                                           inline-c-cpp
                                                         ] ++ pkgs.lib.optionals Hasktorch [
                                                           libtorch-ffi_cpu
                                                           hasktorch-examples_cpu
                                                           hasktorch_cpu
                                                         ] ++ pkgs.lib.optionals Matrix [
                                                           matrix
                                                           hmatrix
                                                         ]
))
