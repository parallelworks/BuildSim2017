#!/bin/bash

echo ""
echo "Generating Geometry..."
echo $@
echo ""

paramString=$1
paramOut=$2
geomOut=$3

HOME=$PWD

cd ${0%/*}  # Run from this directory

# get clean parameters file
python renderParams.py $paramString params.out

# generate geometry
sleep .$[ ( $RANDOM % 2 ) + 1 ]s
run_command="docker run --rm --user root -i -v `pwd`:/scratch -w /scratch parallelworks/openfoam:4.1_paraview"
$run_command python geometry.py params.out interior.stl
ec=$?

if [[ "ec" == "1" ]] || [ ! -e interior.stl ];then
    echo "Retrying Geometry Generation..."
    sleep .$[ ( $RANDOM % 2 ) + 1 ]s
    # try once more in case of api conflicts
    $run_command python geometry.py params.out interior.stl
fi 

# dummy result files
touch keep && mv keep $HOME/$geomOut
echo "" > $HOME/$paramOut

# move the result files
mv interior.stl $HOME/$geomOut
mv params.out $HOME/$paramOut

exit 0
