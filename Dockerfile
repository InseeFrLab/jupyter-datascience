FROM jupyter/datascience-notebook:lab-1.2.5

USER root

# checksum source for libmesos-bundle: https://downloads.mesosphere.com/libmesos-bundle/libmesos-bundle-1.14-alpha.tar.gz.sha256

ARG HADOOP_MAJOR_VERSION="3.2"
ARG HADOOP_SHA256="2d62709c3d7144fcaafc60e18d0fa03d7d477cc813e45526f3646030cd87dbf010aeccf3f4ce795b57b08d2884b3a55f91fe9d74ac144992d2dfe444a4bbf34ee"
ARG HADOOP_URL="https://downloads.apache.org/hadoop/common/hadoop-3.2.1/"
ARG HADOOP_VERSION=3.2.1
ARG HADOOP_AWS_URL="https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws"
ARG SPARK_URL="https://downloads.apache.org/spark/spark-3.0.1/"
ARG SPARK_VERSION=3.0.1
ARG HIVE_URL="https://downloads.apache.org/hive/hive-3.1.2/"
ARG HIVE_VERSION=3.1.2

ENV HADOOP_HOME="/opt/hadoop"
ENV SPARK_HOME="/opt/spark"
ENV HIVE_HOME="/opt/hive"

RUN apt-get -y update && \
    apt-get install --no-install-recommends -y openjdk-8-jre-headless ca-certificates-java && \
    rm -rf /var/lib/apt/lists/*

# Installing mc

RUN wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc && \
    chmod +x /usr/local/bin/mc

# Installing kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl
    
RUN mkdir -p $HADOOP_HOME $SPARK_HOME $HIVE_HOME

RUN cd /tmp \
    && wget ${HADOOP_URL}hadoop-${HADOOP_VERSION}.tar.gz \
    && tar xzf hadoop-${HADOOP_VERSION}.tar.gz -C $HADOOP_HOME --owner root --group root --no-same-owner --strip-components=1 \
    && wget ${HADOOP_AWS_URL}/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar \
    && mkdir -p $HADOOP_HOME/share/lib/common/lib \
    && mv hadoop-aws-${HADOOP_VERSION}.jar $HADOOP_HOME/share/lib/common/lib \
    && wget ${SPARK_URL}spark-${SPARK_VERSION}-bin-without-hadoop.tgz \
    && tar xzf spark-${SPARK_VERSION}-bin-without-hadoop.tgz -C $SPARK_HOME --owner root --group root --no-same-owner --strip-components=1 \
    && wget ${HIVE_URL}apache-hive-${HIVE_VERSION}-bin.tar.gz \
    && tar xzf apache-hive-${HIVE_VERSION}-bin.tar.gz -C $HIVE_HOME --owner root --group root --no-same-owner --strip-components=1 \
    && wget https://jdbc.postgresql.org/download/postgresql-42.2.18.jar \
    && mv postgresql-42.2.18.jar $HIVE_HOME/lib/postgresql-jdbc.jar \
    && rm $HIVE_HOME/lib/guava-19.0.jar \
    && cp $HADOOP_HOME/share/hadoop/common/lib/guava-27.0-jre.jar $HIVE_HOME/lib/ \
    && wget https://repo1.maven.org/maven2/jline/jline/2.14.6/jline-2.14.6.jar \
    && mv jline-2.14.6.jar $HIVE_HOME/lib/ \
    && rm $HIVE_HOME/lib/jline-2.12.jar
    && wget https://repo1.maven.org/maven2/org/apache/spark/spark-hive_2.12/3.0.1/spark-hive_2.12-3.0.1.jar
    && mv spark-hive_2.12-3.0.1.jar $SPARK_HOME/jars/
    && rm -rf /tmp/*

RUN pip install s3fs hvac boto3 pyarrow

RUN pip install jupyterlab-git jupyterlab_latex & \
    jupyter labextension install --no-build @jupyterlab/git @jupyterlab/latex & \
    jupyter serverextension enable --sys-prefix jupyterlab_latex jupyterlab_git

RUN jupyter lab build

ADD spark-env.sh $SPARK_HOME/conf
ADD entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh $SPARK_HOME/conf/spark-env.sh

ENV PYTHONPATH="$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9-src.zip"
ENV SPARK_OPTS --driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M
ENV JAVA_HOME "/usr/lib/jvm/java-8-openjdk-amd64/jre/"
ENV HADOOP_OPTIONAL_TOOLS "hadoop-aws"
ENV PATH="${JAVA_HOME}/bin:${SPARK_HOME}/bin:${HADOOP_HOME}/bin:${PATH}"

VOLUME ["/home/jovyan"]
ENTRYPOINT [ "/opt/entrypoint.sh" ]
