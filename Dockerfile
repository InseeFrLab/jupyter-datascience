FROM jupyter/datascience-notebook

RUN jupyter labextension install @jupyterlab/latex
RUN jupyter serverextension enable --sys-prefix jupyterlab_latex
