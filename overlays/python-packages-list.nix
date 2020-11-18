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
                 #tensorflow
                 Keras
                 pytorch-bin
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
