#!/usr/bin/env python3.8
c.NotebookApp.contents_manager_class = "jupytext.TextFileContentsManager"
c.ContentsManager.notebook_extensions = "ipynb,Rmd,jl,md,py"
c.ServerProxy.servers = {
  'glances': {
    'command': ['glances', '-wp', '{port}']
  },
  'pluto': {
    "command": ["/nix/store/3cldivy6n8911wfksz6kz8p247fc3c36-julia-env/bin/julia", "--optimize=0", "-e", "using Pkg; Pkg.activate(\"./nix/julia2nix\"); using Pluto; Pluto.run(host=\"0.0.0.0\", port={port}, launch_browser=false, require_secret_for_open_links=false, require_secret_for_access=false)"],
    "timeout": 60,
    "launcher_entry": {
        "title": "Pluto.jl",
    },
  },
}
