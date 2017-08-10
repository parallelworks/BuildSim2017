#!/bin/bash

echo "Generating Mesh..."
echo $@
echo ""

paramString=$1
paramOut=$2
geomOut=$3
constraintOut=$4

HOME=$PWD

cd ${0%/*}  # Run from this directory

# get clean parameters file
python renderParams.py $paramString params.out

# generate geometry
sleep .$[ ( $RANDOM % 2 ) + 1 ]s
run_command="docker run --rm --user root -i -v `pwd`:/scratch -w /scratch parallelworks/openfoam:4.1_paraview"
$run_command python geometry.py params.out massing.step
ec=$?

if [[ "ec" == "1" ]] || [ ! -e massing.step ];then
    echo "Retrying Geometry Generation..."
    sleep .$[ ( $RANDOM % 2 ) + 1 ]s
    # try once more in case of api conflicts
    $run_command python geometry.py params.out massing.step
fi

# meshing
run_command="docker run --rm  -i -v `pwd`:/scratch -w /scratch -u 0:0 marmarm/salome:v8_2u"
$run_command salome start -t -w 1 mesh.py args:massing.step,"water/ground/building3/building2/building1/domain/domain_ground/inlet/outlet",output,constraint.txt #2>/dev/null

sudo chmod 777 * -R

# dummy result files
touch keep && mv keep $HOME/$geomOut
echo "" > $HOME/$paramOut
echo "0" > $HOME/$constraintOut

# move the result files
mv output/* $HOME/$geomOut
mv params.out $HOME/$paramOut
mv constraint.txt $HOME/$constraintOut

rm output massing.step -R

exit 0