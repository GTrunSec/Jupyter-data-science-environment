#!/usr/bin/env python3.8
c.NotebookApp.contents_manager_class = "jupytext.TextFileContentsManager"
c.ContentsManager.notebook_extensions = "ipynb,Rmd,jl,md,py"
c.ServerProxy.servers = {
    "pluto": {
        "command": [
            "/nix/store/s57gfh04kc3prjrysgh4igk2qfwfarcz-julia-env/bin/julia",
            "--optimize=0",
            "-e",
            'using Pkg; Pkg.activate("./nix/julia2nix-env"); using Pluto; Pluto.run(host="0.0.0.0", port={port}, launch_browser=false, require_secret_for_open_links=false, require_secret_for_access=false)',
        ],
        "timeout": 60,
        "launcher_entry": {
            "title": "Pluto.jl",
        },
    },
}
