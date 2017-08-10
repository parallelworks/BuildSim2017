#!/bin/bash

echo "Testing Single Radiance Point-in-Time..."

day="06 21"
time="13.0"
cam="170.6011 -323.6221 30.75 4.6396 16.861 0.0 0.0 0.0 1.0"
rad="sample_inputs/geometry.rad"
mat="sample_inputs/material.rad"
sky="+s"
loc="37 122"
viewtype="v"
viewsize="44.5 30.4"
dim="400 300"
falsecolor="false"
fc_max="5"
radparams="-ab 2 -ad 512 -as 20 -ar 64 -aa 0.2 -ps 2 -pt .05 -pj .9 -dj .7 -ds .15 -dt .05 -dc .75 -dr 3 -dp 512 -st .15 -lr 8 -lw .005"
outimg="results/out.bmp"
outtab="results/out.tab"

# run radiance inside docker container
run_command="docker run --rm --user root -i -v `pwd`:/scratch -w /scratch parallelworks/daysim"
$run_command ./runRad.sh "$day" "$time" "$cam" "$rad" "$mat" "$sky" "$loc" "$viewtype" "$viewsize" "$dim" "$falsecolor" "$fc_max" "$radparams" "$outimg" "$outtab"
