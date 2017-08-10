#!/bin/bash

echo ""
echo "Running Radiance Analysis..."
echo ""

# add radiance and daysim to path - static build on docker container
PATH=/opt/daysim/bin:$PATH
PATH=/opt/radiance/bin:$PATH

# parameters
month=$(echo $1 | cut -d " " -f1)
day=$(echo $1 | cut -d " " -f2)
starttime=$2
cam=$3

# settings
rad=$4
mat=$5
sky=$6
loc=$7
lat=$(echo $loc | cut -d "_" -f1 | cut -d " " -f1)
lon=$(echo $loc | cut -d "_" -f2 | cut -d " " -f2)
viewtype=$8
vh=$(echo $9 | cut -d "_" -f1 | cut -d " " -f1)
vv=$(echo $9 | cut -d "_" -f2 | cut -d " " -f2)
xdim=$(echo ${10} | cut -d "_" -f1 | cut -d " " -f1)
ydim=$(echo ${10} | cut -d "_" -f2 | cut -d " " -f2)
falsecolor=${11}
fc_max=${12}
radparams=$(echo ${13} | sed "s/_/ /g")

# outfiles
outfile=${14}
tabfile=${15}

mkdir -p $(dirname $outfile) > /dev/null 2>&1
mkdir -p $(dirname $tabfile) > /dev/null 2>&1

# create the sky file
skyfunc="!gensky $month $day $starttime $sky -a $lat -o $lon"
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
skyfunc glow ground_glow
0
0
4
1 .8 .5 0
ground_glow source ground
0
0
4
0 0 -1 180
EOF

IFS=' ' read -ra camA <<< "$cam"

echo DAY: $month $day
echo TIME: $starttime
echo POS: ${camA[0]} ${camA[1]} ${camA[2]}
echo DIR: ${camA[3]} ${camA[4]} ${camA[5]}
echo UP: ${camA[6]} ${camA[7]} ${camA[8]}
echo RAD: $rad
echo MAT: $mat
echo SKY: $sky
echo LOC: $loc
echo VIEW: $viewtype
echo VH: $vh
echo VV: $vv
echo XDIM: $xdim
echo YDIM: $ydim
echo FALSECOLOR: $falsecolor
echo FC_MAX: $fc_max
echo PAR: $radparams
echo OUT: $outfile
echo TAB: $tabfile
echo ""

# dummy result file in case of failure
echo "no image" > output.bmp

# radiance commands
oconv $mat sky.rad $rad > rad.oct
rpict -t 15 -vt$viewtype -vp ${camA[0]} ${camA[1]} ${camA[2]} -vd ${camA[3]} ${camA[4]} ${camA[5]} -vu ${camA[6]} ${camA[7]} ${camA[8]} -vh $vh -vv $vv -vs 0 -vl 0 -x $xdim -y $ydim $radparams rad.oct > rad.pic

if [[ "$falsecolor" == "true" ]];then
    csh falsecolor2.csh -i rad.pic -s $fc_max -n 10 -m 1 -l Whm-2 > rad_fc.pic
    ra_bmp rad_fc.pic output.bmp
else
    ra_bmp rad.pic output.bmp
fi

# move to swift needed output file
mv output.bmp $outfile

# get the average value
pvalue -h -H -df rad.pic | total -if1 -m > rad.ave
ave=$(printf '%.3f' $(cat rad.ave))

# get the min/max values
pextrem rad.pic > rad.extrem
min=$(printf '%.0f' $(cat rad.extrem | head -n1 | cut -d " " -f3))
max=$(printf '%.0f' $(cat rad.extrem | tail -n1 | cut -d " " -f3))

# export metrics to tab delimited file
echo -e $(basename $outfile .bmp)' \t '$min' \t '$ave' \t '$max > $tabfile

# clean up the files
rm *.pic *.extrem *.oct sky.rad *.ave
