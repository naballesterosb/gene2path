#!/bin/bash

getIDs(){
	local iFile=$1
	
	awk '
	($1~">"){
		s=split($0,arr,"[>|[:blank:]]+")
		
		for(i=2;i<=s;i++){
			if( arr[i]~/^[[:upper:][:digit:]._]+[[:digit:]]+$/ && length(arr[i])>5 ){
				if( arr[i-1]~/^[[:lower:]]+$/ && length(arr[i-1])<4 )
					map[ arr[i-1]":"arr[i] ] = 1
				else
					map[ arr[i] ] = 1
			}else if( arr[i]~/^[[:alpha:]]+$/ && length(arr[i])>5 ){
				break
			}
		}
	}
	END{
		for( item in map )
			print item
	}
	' $iFile > .values
	
	cat .values | awk '{ printf "%30s", $1 }END{ print "" }'
	
	rm .values
}

main(){
	for iFile in $*
	do
		getIDs $iFile
	done
}

main $*