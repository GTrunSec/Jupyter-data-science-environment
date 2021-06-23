{ ... }:

{
  flakeLock = (builtins.fromJSON (builtins.readFile ../flake.lock)).nodes;
  loadInput = { locked, ... }:
    assert locked.type == "github";
    builtins.fetchTarball {
      url = "https://github.com/${locked.owner}/${locked.repo}/archive/${locked.rev}.tar.gz";
      sha256 = locked.narHash;
    };
}
