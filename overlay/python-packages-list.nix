{pkgs}:
(with pkgs.python3.withPackages; (p: with p;  [ jsondiff
                                                geoip2
                                                numpy pandas matplotlib editdistance ipywidgets
                                                graphviz pillow elasticsearch requests sqlalchemy
                                                qtconsole
                                                sympy
                                                fastai2
                                                fastai
                                                zat
                                                #financial machine learning.
                                                mlfinlab
                                                tqdm
                                                tensorflow
                                                patsy
                                                Keras
                                                dask
                                                pyfolio
                                              ]))
