#!/usr/bin/env bash
echo "affichage du path"
echo $PATH
echo "affichage de la home java"
echo $JAVA_HOME
SPARK_DIST_CLASSPATH=$(hadoop classpath)
