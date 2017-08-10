#!/bin/bash

outcsv=$1
outhtml=$2
rpath=$3
kpi=$4

outputs4DE="models/mexdex/DEoutputParams.txt"
caseslistFile="cases.list"
desiredMetricsFile=$kpi
metricsFilesNameTemplate="results/metrics/case_@@i@@.csv"
pngOutDirRoot="results/case_"

colorby="viewscore_ave"

echo $@

if [[ "$rpath" == *"/efs/job_working_directory"* ]];then
    basedir="$(echo /download$rpath | sed "s|/efs/job_working_directory||g" )"
    DEbase="/preview"
else
    # cloud 9 development
    host=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
    basedir="$(echo $rpath | sed 's|/core|http://'$host':8080/preview|g')"
    DEbase="http://$host:8080/preview/share"
fi

# Works with both python2 and python3 
python models/mexdex/writeDesignExplorerCsv.py $caseslistFile $desiredMetricsFile $basedir output.csv $pngOutDirRoot $metricsFilesNameTemplate $outputs4DE 
mv output.csv $outcsv

baseurl="$DEbase/DesignExplorer/index.html?datafile=$basedir/$outcsv&colorby=$colorby"
echo '<html style="overflow-y:hidden;background:white"><a style="font-family:sans-serif;z-index:1000;position:absolute;top:15px;right:0px;margin-right:20px;font-style:italic;font-size:10px" href="'$baseurl'" target="_blank">Open in New Window</a><iframe width="100%" height="100%" src="'$baseurl'" frameborder="0"></iframe></html>' > $outhtml

