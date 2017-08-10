#!/bin/bash

# run radiance inside docker container
chmod 777 * -R # open all permissions
run_command="docker run --rm -i -v `pwd`:/scratch -w /scratch mattshax/daysim"
$run_command ./model/runRad.sh "$@"
