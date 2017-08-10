#!/bin/bash

echo ""
echo "Running Radiance Analysis..."
echo ""
echo $@
echo ""

# add radiance and daysim to path - static build on docker container
PATH=/opt/daysim/bin:$PATH
PATH=/opt/radiance/bin:$PATH

month=$1
day=$2
starttime=$3
lat=$4
lng=$5
cam=$6
infile=$7
outfile=$8

mkdir -p $(dirname $outfile) > /dev/null 2>&1

# convert the obj geometry to rad
# specify a Rhino map file with -m file.map
./obj2rad -o obj -f $infile > geom.rad

# create the sky and material files
cat <<EOF> mat.rad
# Material Definition
void plastic massing
0 
0 
5 0.35 0.35 0.35 0 0
EOF

skyfunc="!gensky $month $day $starttime +s -a $lat -o $lng"
cat <<EOF> sky.rad
# Sky Definition
${skyfunc}
skyfunc glow sky_mat
0
0
4
1 1 1 0
sky_mat source sky
0
0
4
0 0 1 180
EOF

IFS=' ' read -ra camA <<< "$cam"

echo DAY: $month $day
echo TIME: $starttime
echo LAT: $lat
echo LNG: $lng
echo IN: $infile
echo OUT: $outfile
echo POS: ${camA[0]} ${camA[1]} ${camA[2]}
echo DIR: ${camA[3]} ${camA[4]} ${camA[5]}
echo UP: ${camA[6]} ${camA[7]} ${camA[8]}
echo ""

# radiance commands
oconv mat.rad sky.rad geom.rad > rad.oct 2> /dev/null
rpict -t 15 -i -ab 2 -ad 512 -as 20 -ar 64 -aa 0.2 -vtv -vp ${camA[0]} ${camA[1]} ${camA[2]} -vd ${camA[3]} ${camA[4]} ${camA[5]} -vu ${camA[6]} ${camA[7]} ${camA[8]} -vh 26.24 -vv 26.99 -vs 0 -vl 0  -x 400 -y 300 rad.oct > rad.pic
csh falsecolor2.csh -i rad.pic -s 400 -n 10 -m 1 -l watt-hr/m2 -mask 0.00001 > rad_fc.pic
ra_bmp rad_fc.pic output.bmp

# move to swift needed output file
mv output.bmp $outfile

# clean up the files
rm *.pic *.extrem *.oct sky.rad *.ave *.rad  > /dev/null 2>&1
