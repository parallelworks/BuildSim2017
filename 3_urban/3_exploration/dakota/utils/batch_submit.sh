#!/bin/bash

cases=$1
workdir=$2

caselistLocation=$workdir/cases.list

export PATH=$PATH:/swift-k-bin/bin

evalidLocation=$workdir/evalid_caseid.txt
mkdir $workdir/results > /dev/null 2>&1
rm $caselistLocation > /dev/null 2>&1
rm $evalidLocation > /dev/null 2>&1
counter=0

for aa in $(cat $cases)
do
	rm cases.list.tmp > /dev/null 2>&1
	
	for line in $(cat $aa/input.in);do
    	pname=$(echo $line | cut -d ";" -f1)
    	pval=$(echo $line | cut -d ";" -f3)
    	echo $pname:$pval >> cases.list.tmp
	done
	
	cat cases.list.tmp | tr '\n' ',' | rev | cut -c 2- | rev >> $caselistLocation
	
	#cat $aa/input.in | tr '\n' ',' | sed  's/;/=/g' | rev | cut -c 2- | rev >> $caselistLocation
	echo "$aa+$counter" >> $evalidLocation
	let counter=counter+1
done

cd $workdir

echo ""
swift -config swift.conf main.swift

cd ..

for bb in $(cat $evalidLocation)
do
	folder=$(echo $bb | cut -d "+" -f 1)
	caseid=$(echo $bb | cut -d "+" -f 2)
	mkdir -p $folder/results/case_0 > /dev/null 2>&1
	mkdir -p $folder/results/metrics > /dev/null 2>&1
	cp -ar $workdir/results/case_$caseid/* $folder/results/case_0
	cp -ar $workdir/results/metrics/case_$caseid.csv $folder/results/metrics/case_0.csv
	echo "1" > $folder/READY_RETURN.txt	
done

echo ""
