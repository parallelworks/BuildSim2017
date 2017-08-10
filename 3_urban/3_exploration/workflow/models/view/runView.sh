#!/bin/bash

geomLocation=$1
metricsOut=$2
imagesOut=$3
kpi=$4

HOME=$PWD

cd ${0%/*}  # Run from this directory

# move geometry and mexdex scripts to run directory
cp $HOME/$geomLocation output -R
cp $HOME/mexdex ./ -R > /dev/null 2>&1
cp $HOME/models/mexdex ./ -R > /dev/null 2>&1 # for plugging into workflow
cp $HOME/$kpi ./ -R > /dev/null 2>&1
cp $HOME/models/$kpi ./ -R > /dev/null 2>&1 # for plugging into workflow
kpi=$(basename $kpi)
sudo chmod 777 * -R

# view analysis
run_command="docker run --rm -i -v `pwd`:/scratch -w /scratch parallelworks/openfoam:4.1_cyclone"
$run_command bash -c 'export PATH=$PATH:/opt/paraview540/bin;pvpython view.py output "building1/building2/building3" "water"'

# extract results
run_command="docker run --rm  -i --user root -v `pwd`:/scratch -w /scratch parallelworks/openfoam:4.1_cyclone"
$run_command ./mexdex/extract.sh /opt/paraview540/bin mexdex/extract.py output/viewscore.vtk $kpi metrics metrics.csv

sudo chmod 777 * -R

# dummy result files to ensure dakota continues
touch keep && mv keep $HOME/$imagesOut
echo metric,ave,min,max,sd > $HOME/$metricsOut
echo viewscore,0,0,0,0 >> $HOME/$metricsOut

# move the result files
mv *.tar $HOME/$imagesOut
mv metrics/* $HOME/$imagesOut
mv metrics.csv $HOME/$metricsOut

# cleanup 
rm mexdex metrics output kpi.json -R

exit 0