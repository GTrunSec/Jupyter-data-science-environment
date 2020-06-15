self: super:
{
  julia_13 = super.julia_13.overrideAttrs(oldAttrs: {
   src = super.fetchzip {
     url = "https://github.com/JuliaLang/julia/releases/download/v1.4.2/julia-1.4.2-full.tar.gz";
     sha256 = "14jghi9mw0wdi6y9saarf0nzary9i21jx43zznddzrq48v4nlayj";
   };
   checkTarget = "";
  });
}
