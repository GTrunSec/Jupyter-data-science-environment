self: super:
{
  julia_13 = super.julia_13.overrideAttrs(oldAttrs: {
   src = super.fetchzip {
     url = "https://github.com/JuliaLang/julia/releases/download/v1.5.1/julia-1.5.1-full.tar.gz";
     sha256 = "sha256-uaxlzni2RtmDhMzPbtDycj44CB0tJUzhmbwsAGwFv/U=";
   };
   checkTarget = "";
  });
}
