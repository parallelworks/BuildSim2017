#! /bin/bash

outgif=$1
outplot=$2

convert -delay 10 -loop 0 -gravity South -background Black -fill White -splice 0x18 -annotate +0+2 "%f" output/bmp/* output.gif

mv output.gif $outgif

# CREATE A GNUPLOT OF THE RESULTS
for f in output/tab/*;do
    echo $(cat $f|cut -d "_" -f4) >> graphtmp.txt
done
title=$(cat $f|cut -d "_" -f3)
cat <<EOF> plotiteration
set terminal png size 390,300 enhanced font "Arial,8" x000000 xffffff
set output "plot.png"
unset key
set title "Rpict Results: $title"
set xlabel "Time"
set ylabel "Wh/m2 (Average)"
set xtics rotate
set grid
set tics out
set format y "%g";
set yrange [0:*]
#set xrange [0:*]
plot "graphtmp.txt" u 3:xtic(1) with lines
EOF
gnuplot plotiteration
mv plot.png $outplot
