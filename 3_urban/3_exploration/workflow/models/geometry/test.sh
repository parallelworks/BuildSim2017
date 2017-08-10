#!/bin/bash

# run the geometry model
casestring="building1_height:15,building2_height:15,building3_height:15"
caseParams="outputs/params.txt"
geomLocation="outputs"
constraintOut="outputs/area.txt"

mkdir -p $geomLocation > /dev/null 2>&1
./genMesh.sh $casestring $caseParams $geomLocation $constraintOut
