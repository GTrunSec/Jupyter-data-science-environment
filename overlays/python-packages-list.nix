{ pkgs
, MachineLearning ? false
, DataScience ? false
, Financial ? false
, Graph ? false
, SecurityAnalysis ? false
}:
(p: with p;  [ jsondiff
               elasticsearch
               requests
               sqlalchemy
               qtconsole
               sympy
               #nbdev
             ]  ++ pkgs.lib.optionals DataScience [
               numpy
               pandas
               # fastai2
               # fastai
             ] ++ pkgs.lib.optionals Graph [
               #editdistance
               ipywidgets
               graphviz
               geoip2
               pillow
               matplotlib
             ] ++ pkgs.lib.optionals MachineLearning [
               (if pkgs.python.passthru.isPy38 then tensorflow_2 else "")
               Keras
               (if pkgs.python.passthru.isPy38 then pytorch_bin else pytorch)
             ]  ++ pkgs.lib.optionals Financial [
               #financial machine learning.
               #mlfinlab
               tqdm
               patsy
               dask
               #pyfolio
             ] ++ pkgs.lib.optionals SecurityAnalysis [
               #zat
             ]

)
