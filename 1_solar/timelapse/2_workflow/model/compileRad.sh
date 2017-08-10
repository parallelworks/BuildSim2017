#! /bin/bash

outhtml=$1
outtar=$2
outtab=$3

# we know this from the swift script
resultdir=output

# render simple html viewer
echo "<body style='background:black;text-align:center'>" > tmp.html
for f in $resultdir/gif/*;do
    echo "<img height='300px' src=\"data:image/gif;base64,$(base64 -w 0 $f)\"/>" >> tmp.html
    echo "<img height='300px' src=\"data:image/png;base64,$(base64 -w 0 $(echo $f|sed 's/gif/png/g'))\"/>" >> tmp.html
    echo "<br>" >> tmp.html
done
echo "</body>" >> tmp.html
mv tmp.html $outhtml

# tar the result gif animations
tar -czf tmp.tgz $resultdir/gif $resultdir/png
mv tmp.tgz $outtar

# compile the metrics
echo -e id_month-day-time' \t 'min' \t 'ave' \t 'max > tmp.tab
for f in $resultdir/tab/*;do
    cat $f >> tmp.tab
done
mv tmp.tab $outtab


