FROM jupyter/datascience-notebook

RUN pip install jupyterlab_latex & \
    jupyter labextension install @jupyterlab/latex & \
    jupyter serverextension enable --sys-prefix jupyterlab_latex

RUN jupyter labextension install jupyterlab-s3-browser & \
    pip install jupyterlab-s3-browser

RUN jupyter serverextension enable --py jupyterlab_s3_browser

