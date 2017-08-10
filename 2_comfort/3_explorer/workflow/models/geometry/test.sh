#!/bin/bash

# run the geometry model
casestring="duct_outlet_length:1,duct_outlet_width:0.25,inlet_temp:280,floor_flux:800,glass_temp:300,inlet_velocity:10"
caseParams="outputs/params.txt"
geomLocation="outputs"

mkdir -p $geomLocation > /dev/null 2>&1
./genGeometry.sh $casestring $caseParams $geomLocation 
