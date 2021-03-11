{ system ? builtins.currentSystem
, ...
}:
let
  fetch = import ./compat/fetch.nix;
  devshell' = fetch "devshell";
  pkgs = import (fetch "nixpkgs") { };
  devshell = import devshell' {
    inherit system;
  };
in
devshell.mkShell rec {

  name = "my-julia2nix-env";

  packages = with pkgs; [
    direnv
  ];

  env = [
    {
      name = "JULIA_DEPOT_PATH";
      value = "./.julia_depot";
    }
    {
      name = "PATH";
      prefix = "bin";
    }
    {
      name = "DIR";
      prefix = ''
        $( cd "$(dirname "$\{\BASH_SOURCE [ 0 ]}")"; pwd )
      '';
    }
  ];
  commands = with pkgs; [
    {
      name = "julia2nix";
      command = ''
        if [ ! -d  "./julia2nix" ]; then
        ${pkgs.git}/bin/git clone https://github.com/GTrunSec/julia2nix
        fi
        julia2nix/julia2nix && nix-build
        $(nix-build . --no-out-link)/bin/julia -e 'import Pkg; Pkg.instantiate()'
      '';
      category = "julia2nix";
      help = "generate the Julia Pkg's Nix expression and build Packages";
    }
    {
      name = "julia";
      command = ''
        $(nix-build . --no-out-link)/bin/julia -L $DIR/startup.jl $@
      '';
      category = "julia";
      help = "wrapped Julia executable";
    }
    {
      name = "pluto";
      command = ''
        eval $(echo "$(nix-build . --no-out-link)/bin/julia -e 'import Pkg; Pkg.activate(\".\"); using Pluto; Pluto.run(host=\"$1\", port=8889)'")
      '';
      category = "julia_package";
      help = "launch pluto server";
    }
    {
      name = "addPackage";
      command = ''
        eval $(echo "$(nix-build . --no-out-link)/bin/julia -e 'using Pkg; Pkg.activate(\"$1\"); Pkg.add([$2])'")
        # cleanup JULIA_DEPOT_PATH for Julia2nix Build
        julia2nix/julia2nix && nix-build
        #rm -rf $JULIA_DEPOT_PATH
      '';
      category = "julia_package";
      help = ''
        Exp: addPackage . '\"StatsFuns, Images\"' -> <activatePath> <Package Name List>
      '';
    }
  ];
}
