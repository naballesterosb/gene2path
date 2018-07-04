#!/bin/bash

iFile1=$1
iFile2=$2
sep=$3

if [ -z "$iFile1" -a -z "$iFile2" ]
then
	echo "Usage:"
	echo "        join.sh file1 file2 [separator]"
	exit
fi

if [ -z "$sep" ]
then
	sep="   "
fi

awk '
BEGIN{
	while( ( getline < "'$iFile1'" ) > 0 ){
		if( ! $1 in map )
			map[$1]=""
		
		for( i=2; i<=NF; i++ ){
			if( match( map[$1], "'"$sep"'"$i ) == 0 )
				map[$1]=map[$1]"'"$sep"'"$i
		}
	}
	close("'$iFile1'") 
	
	while( ( getline < "'$iFile2'" ) > 0 ){
		if( ! $1 in map )
			map[$1]=""
			
		for( i=2; i<=NF; i++ ){
			if( match( map[$1], "'"$sep"'"$i ) == 0 )
				map[$1]=map[$1]"'"$sep"'"$i
		}
	}
	close("'$iFile2'") 
	
	for( item in map )
		print item""map[item]
}
'

