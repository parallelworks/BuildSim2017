#!/bin/bash

echo "Testing Single Radiance Point-in-Time..."

month="06"
day="21"
time="13.0"
lat="37"
lng="122"
cam="-435.82 -231.03 452.73 387.37 348.45 -439.65 0 0 1"
infile="sample_inputs/geometry.obj"
outfile="results/out_$month-$day-$time.bmp"

# run radiance inside docker container
run_command="docker run --rm -i -v `pwd`:/scratch -w /scratch mattshax/daysim"
$run_command ./runRad.sh "$month" "$day" "$time" "$lat" "$lng" "$cam" "$infile" "$outfile"
