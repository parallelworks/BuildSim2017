#!/bin/bash

echo ""
echo "Running Comfort Analysis..."
echo $@
echo ""

geomLocation=$1
metricsOut=$2
imagesOut=$3
caseParams=$4
kpi=$5

HOME=$PWD

cd ${0%/*} || exit 1  # Run from this directory

# move geometry and mexdex scripts to run directory
cp $HOME/mexdex ./ -R > /dev/null 2>&1
cp $HOME/models/mexdex ./ -R > /dev/null 2>&1 # for plugging into workflow
cp $HOME/$kpi ./ > /dev/null 2>&1
cp $HOME/models/$kpi ./ > /dev/null 2>&1 # for plugging into workflow
kpi=$(basename $kpi)
sudo chmod 777 * -R

# replace the openfoam stl file
cp $HOME/$geomLocation/*.stl constant/triSurface/
cp 0.template 0.orig -R
cp system.template system -R

# replace the params in the case files
echo "Replacing parameters:"
while IFS='' read -r line || [[ -n "$line" ]]; do
	pname=$(echo $line | cut -d ":" -f1 | tr -d '[:space:]')
    pval=$(echo $line | cut -d ":" -f2 | tr -d '[:space:]')
    echo $pname $pval
    find ../openfoam -type f  -not -path "*/polyMesh/*" -not -path "*/0.template/*" -not -path "*/system.template/*" -exec sed -i "s/@@$pname@@/$pval/g" {} \;
done < $HOME/$caseParams
echo "Done replacing parameters"

# comfort analysis
run_command="docker run --rm --user root -i -v `pwd`:/scratch -w /scratch parallelworks/openfoam:4.1_paraview"
$run_command ./runOpenFOAM.sh

# extract results
run_command="docker run --rm --user root  -i -v `pwd`:/scratch -w /scratch parallelworks/openfoam:4.1_paraview"
$run_command ./mexdex/extract.sh /opt/paraview540/bin mexdex/extract.py system/controlDict $kpi metrics metrics.csv

sudo chmod 777 * -R

# dummy result files to ensure dakota continues
touch keep && mv keep $HOME/$imagesOut
echo metric,ave,min,max,sd > $HOME/$metricsOut
echo viewscore,0,0,0,0 >> $HOME/$metricsOut

# move the result files
mv metrics/* $HOME/$imagesOut
mv metrics.csv $HOME/$metricsOut
