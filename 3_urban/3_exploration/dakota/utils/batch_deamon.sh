#!/bin/bash

# kill existing batch runners
#kill -9 $(ps -x | grep /templatedir/batch_deamon.sh | awk '{ print $1 }' | tr '\n' ' ')

rm deamon_jobs*.txt > /dev/null 2>&1
echo $$ > deamon_pid.txt

counter=0
timecount=0
num_cases=0

timewait=20

cat params.run | tr '|' '\n' > tmp.params.run

eval_con=$(cat tmp.params.run | grep eval_con | cut -d ";" -f3)
num_exp=$(cat tmp.params.run | grep num_exp | cut -d ";" -f3)

while [ 1 ]
do

	#echo "Waiting for Batch $counter - $timecount"

	for ii in work_dir/*
	do
		if [ -e $ii/READY_SWIFT.txt ]
		then
			let num_cases=$num_cases+1
			echo $ii >> deamon_jobs_$counter.txt
			rm $ii/READY_SWIFT.txt
		fi		

	done
	
	#echo "Num Cases:" $num_cases
	
	#eval_con=2 # temp for testing
	
	runBatch=false
	
	# if num_cases == dakota evaluation concurrency, run a batch
	if [ "$num_cases" -eq "$eval_con" ] || [ "$num_cases" -eq "$num_exp" ];then
		echo "Batch Concurrency Met..."
		runBatch=true
	fi
	
	if [ "$timecount" -ge "$timewait" ] &&  [ "$num_cases" -gt "0" ]; then
		echo "Batch Timeout Met..."
		runBatch=true
	fi
	
	#echo RunBatch: $runBatch
	
	if [[ "$runBatch" == "true" ]];then
		echo ""
		echo "Running Batch $counter..."
		cp -ar templatedir batch_work_$counter
		cp deamon_jobs_$counter.txt batch_work_$counter
		./templatedir/batch_submit.sh batch_work_$counter/deamon_jobs_$counter.txt batch_work_$counter & $1>batch_work_$counter/batch_stdout.txt $2>batch_work_$counter/batch_stderr.txt
		let counter=$counter+1
		let timecount=0
		let num_cases=0
	fi

	sleep 1
	let timecount=$timecount+1

	if [ "$timecount" -ge "$timewait" ] &&  [ "$num_cases" -eq "0" ]; then
		let timecount=0
	fi

done
