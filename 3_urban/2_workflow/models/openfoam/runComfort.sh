#!/bin/bash

run_command="docker run --rm --user root -i -v `pwd`:/scratch -w /scratch parallelworks/openfoam:4.1_comfortfoam"
$run_command ./runOpenFOAM.sh

run_command="docker run --rm --user root  -i -v `pwd`:/scratch -w /scratch marmarm/paraview:v5_4u_imgmagick"
$run_command ./extract.sh /opt/paraview530/bin utils/extract.py system/controlDict kpi.json metrics metrics/metrics.csv

