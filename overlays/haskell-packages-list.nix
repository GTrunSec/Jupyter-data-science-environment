{ pkgs
, Diagrams ? false
, InlineC ? false
, Hasktorch ? false
, Matrix ? false
}:
(with pkgs.haskellPackages.ghcWithPackages; (p: with p;  [ hvega
                                                           formatting
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
                                                           #random-fu failure with 884
                                                         ] ++ pkgs.lib.optionals Diagrams [
                                                           diagrams
                                                           Chart
                                                           ihaskell-diagrams
                                                           ihaskell-hvega
                                                           ihaskell-blaze
                                                           ihaskell-charts
                                                           inline-r
                                                         ] ++ pkgs.lib.optionals InlineC [
                                                           inline-c
                                                           inline-c-cpp
                                                         ] ++ pkgs.lib.optionals Hasktorch [
                                                           # libtorch-ffi_cpu
                                                           # hasktorch-examples_cpu
                                                           #hasktorch_cpu
                                                         ] ++ pkgs.lib.optionals Matrix [
                                                           matrix
                                                           hmatrix
                                                         ]
))
