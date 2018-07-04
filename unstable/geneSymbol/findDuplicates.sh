#!/bin/bash

iFile=$1
check=$2

if [ "$check" = "check" ]
then
	awk '{if($1 in map) map[$1]+=1; else map[$1]=1}END{for( val in map ) if(map[val]>1) print val," ==> ",map[val] }' $iFile
elif [ "$check" = "fix" ]
then
	awk '{if($1 in map) map[$1]+=1; else{ map[$1]=1;line[$1]=$0 }}END{for( val in map ) print line[val] }' $iFile
fi