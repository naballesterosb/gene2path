#!/bin/bash

ifile=$1
specie=$2

printf "#%14s%15s%15s%15s%25s%15s    " "JC-ID" "gb-IDtrout" "UniGeneTrout" "Omy" "UniGene-$specie" "%-homology"
echo "NameProtein"

suff=$$
for gbID0 in `cat $ifile`
do
	homology.sh -i $gbID0 -s $specie > .output$suff
	
	if [ -f .output$suff -a -n "`cat .output$suff`" ]
	then
		unigeneTrout=`cat .output$suff | grep "UniGeneTrout" | awk '{print $2}'`
		omy=`cat .output$suff | grep "Omy" | awk '{print $2}'`
		gbID=`cat .output$suff | grep "gbID" | awk '{print $2}'`
		protName=`cat .output$suff | grep "protName" | sed 's/protName:/ /g'`
		geneLd=`cat .output$suff | grep "ld" | awk '{print $2}'`
		geneID=`cat .output$suff | grep "geneID" | awk '{print $2}'`
		
		geneJCID=`troutDict.sh $gbID | awk '{print $NF}'`
		
		if [ -n "$geneID" ]
		then
			printf "%15s%15s%15s%15s%25s%15s    " $geneJCID $gbID $unigeneTrout $omy $geneID $geneLd
			echo $protName
		fi
	fi
	
	rm -rf .output$suff
done
