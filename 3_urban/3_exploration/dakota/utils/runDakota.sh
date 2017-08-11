#! /bin/bash

study=$1
datfile=$2
htmlfile=$3
path=$4

sudo chmod 777 * -R

INSTALL_DIR=/dakota
export PATH=$PATH:$INSTALL_DIR/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$INSTALL_DIR/lib:$INSTALL_DIR/bin
export PYTHONPATH=$PYTHONPATH:$PWD/utils

echo "Running $study Analysis"

usebatch=true
if [ "$usebatch" == "true" ] ;then
    echo "Running batch deamon"
    ./templatedir/batch_deamon.sh &
fi

if [[ "$study" == "soga" ]] || [[ "$study" == "soga_surr" ]];then
    mv templatedir/plot.html ./
    mv templatedir/soga-results.html ./
fi

echo ""
dakota -input templatedir/$study.in
ec=$?

if [ -f "out.dat" ] && [ "$ec" == "0" ];then
    cp out.dat $datfile
else
    echo "error with dakota run"
    exit 1
fi

# convert the samples file 
#genResponse() {
#awk 'BEGIN {FS=" "};NR > 1 {print $2,$3,'\$$2'}' $1 > out_dace.spd
#cat > out_dace.spk << END
# Load[name = test, file = 'out_dace.spd', n_predictors = 2,n_responses = 1]
# CreateAxes[name = ax_2d, bounds = 'INLET5_X_MIN INLET5_X_MAX | INLET6_Y_MIN INLET6_Y_MAX ']
# CreateSample[name = test_data, axes = ax_2d, grid_points = (100,100),labels = (radius,height)]
# CreateSurface[name = kriging_branin_local, data = test, type = kriging, lower_bounds = (INLET5_X_MIN, INLET6_Y_MIN), upper_bounds = (INLET5_X_MAX, INLET6_Y_MAX), optimization_method = local ]
# Evaluate[surface = kriging_branin_local, data = test_data, label = kriging]
# Save[data = test_data, file = '$3']
#END
#surfpack out_dace.spk
#rm out_dace.spk out_dace.spd
#}

#echo "Generating the Response Surfaces"
#genResponse out_dace.dat 4 out_surrogate_area.dat
#genResponse out_dace.dat 5 out_surrogate_volume.dat

#python templatedir/graph.py $htmlfile

if [[ "$study" == "doe" ]];then
    python templatedir/graph_sensitivity.py $datfile @@NUMBER_OF_INPUTS@@  $htmlfile
fi

if [[ "$study" == "soga" ]] || [[ "$study" == "soga_surr" ]];then
    #python templatedir/graph_soga.py $datfile $htmlfile

pwpath="/export/galaxy-central/database/job_working_directory"
if [[ "$path" == *"$pwpath"* ]];then
    basedir="$(echo /download$path/$(basename $datfile) | sed "s|$pwpath||g" )"
    paramsrun="$(echo /download$path/params.run | sed "s|$pwpath||g" )"
    sed -i "s|soga.dat|$basedir|g" soga-results.html
    sed -i "s|../params.run|$paramsrun|g" soga-results.html
else
    sed -i "s|soga.dat|$(basename $datfile)|g" soga-results.html
fi
    cp soga-results.html $htmlfile
fi

#delete dakota files
./templatedir/dakota_cleanup

exit 0