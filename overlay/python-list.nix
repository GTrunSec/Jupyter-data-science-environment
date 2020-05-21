{pkgs}:
(with pkgs.python3.withPackages; (p: with p;  [ jsondiff
                                                geoip2
                                                numpy pandas matplotlib editdistance ipywidgets
                                                graphviz pillow elasticsearch requests sqlalchemy
                                                qtconsole
                                                own-pydicom
                                                (own-geoip2.overridePythonAttrs (oldAttrs: {
                                                      propagatedBuildInputs = with pythonPackages; [ requests
                                                                                                     (pythonPackages.maxminddb.overridePythonAttrs ( oldAttrs:{
                                                                                                           src = pythonPackages.fetchPypi {
                                                                                                                 version = "1.5.2";
                                                                                                                 pname = "maxminddb";
                                                                                                                 sha256 = "d0ce131d901eb11669996b49a59f410efd3da2c6dbe2c0094fe2fef8d85b6336";
                                                                                                           };
                                                                                                     }))
                                                                                                   ];
                                                }))

                                                ]))
