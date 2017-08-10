#!/bin/bash

command=$1
shift 1

run_command="docker run --rm -i -v `pwd`:/scratch -w /scratch avidalto/blender:v20"

#echo $run_command blender "-b" "--python" $command "$@"
$run_command blender "-b" "--python" $command "$@"
