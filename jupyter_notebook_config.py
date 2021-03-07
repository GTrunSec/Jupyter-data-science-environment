#!/usr/bin/env python3.8
c.NotebookApp.contents_manager_class = "jupytext.TextFileContentsManager"
c.ContentsManager.notebook_extensions = "ipynb,Rmd,jl,md,py"
c.ServerProxy.servers = {
  'glances': {
    'command': ['glances', '-wp', '{port}']
  },
  'pluto': {
    "command": ["/nix/store/ga513yhcbjhbhsqqns22pv3bygrdm3g8-julia-env/bin/julia", "--optimize=0", "-e", "import Pluto; Pluto.run(host=\"0.0.0.0\", port={port}, launch_browser=false, require_secret_for_open_links=false, require_secret_for_access=false)"],
    "timeout": 60,
    "launcher_entry": {
        "title": "Pluto.jl",
    },
  },
}
