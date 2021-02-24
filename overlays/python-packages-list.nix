{ pkgs
, MachineLearning ? false
, DataScience ? false
, Financial ? false
, Graph ? false
, SecurityAnalysis ? false
, Sas ? false
}:
(p: with p;  [
  jsondiff
  elasticsearch
  requests
  sqlalchemy
  qtconsole
  sympy
] ++ pkgs.lib.optionals DataScience [
  numpy
  pandas
  nbdev
  fastai
] ++ pkgs.lib.optionals Graph [
  editdistance
  ipywidgets
  graphviz
  geoip2
  pillow
  matplotlib
] ++ pkgs.lib.optionals MachineLearning [
  (if python.passthru.pythonVersion < "3.8" then tensorflow_2 else "")
  Keras
  pytorch
] ++ pkgs.lib.optionals Financial [
  #financial machine learning.
  mlfinlab
  tqdm
  patsy
  dask
  pyfolio
] ++ pkgs.lib.optionals SecurityAnalysis [
  zat
  zqd
  textblob
  pycountry
  seaborn
  python-Levenshtein
] ++ pkgs.lib.optionals Sas [
  saspy
  sas_kernel
]

)
