#!/bin/bash

study=$1
paramsrun=$2
jsonfile=$3
workflowdir=$4

mkdir templatedir

#using rsync instead of cp because cp exit with 1 when folders are omitted
rsync -a $workflowdir/ templatedir/
rsync dakota/methods/$study.in templatedir/
rsync dakota/utils/* templatedir/
rsync swift.conf templatedir/
rsync $paramsrun templatedir/

sed -i "s/localhost/$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/g" templatedir/swift.conf

# needed for surrogate modeling
if [[ "$study" == "surr" ]] || [[ "$study" == "soga_surr" ]];then
    points=$5
    samples=$6
    rsync $points ./points.dat
    rsync $samples ./samples.dat
fi

python templatedir/input_parser.py $study templatedir/$paramsrun templatedir/input.template templatedir/$jsonfile templatedir/$study.in templatedir/runDakota.sh
