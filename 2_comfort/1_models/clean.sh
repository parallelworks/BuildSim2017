
rm outputs -R > /dev/null 2>&1

cd openfoam

rm 100 500 0 processor* kpi.json mexdex 0.orig system *.tar metrics constant/polyMesh/* comfort.log comfort.txt -R > /dev/null 2>&1

cd ../