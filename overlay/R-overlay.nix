_: pkgs:
let
   customRPackages = with pkgs.rPackages;[
        bookdown
   ];
in
{
  R-with-my-packages = pkgs.rWrapper.override{
              packages = customRPackages;
      };
}
