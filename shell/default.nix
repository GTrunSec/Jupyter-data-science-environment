{ channels, self, inputs }:
with channels.nixpkgs;
devshell.mkShell {
  name = "devShell";
  packages = [ ];
  imports = [ (devshell.importTOML ./devshell.toml) ];
  commands = [ ];
}
