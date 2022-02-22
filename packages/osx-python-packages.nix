{pkgs}: (with pkgs.python3.withPackages; (p:
  with p; [
    geoip2
    numpy
    pandas
    matplotlib
    editdistance
    ipywidgets
    graphviz
    pillow
    elasticsearch
    requests
    sqlalchemy
    qtconsole
    sympy
    nbdev
    # fastai2
    # fastai
    #zat failed by pyarrow
    #financial machine learning.
    #tensorflow
    Keras
    dask
    pyfolio
  ]))
