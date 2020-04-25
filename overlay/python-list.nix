{pkgs}:
(with pkgs.python3.withPackages; (p: with p;  [ jsondiff
                                                geoip2
                                                numpy pandas matplotlib editdistance ipywidgets
                                     ]))
