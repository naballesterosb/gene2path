#!/bin/bash

# $REQUEST_METHOD

Form_TMPDIR=""

Form.init()
{
	Form_TMPDIR=/tmp/query$$
	mkdir $Form_TMPDIR
	cat $QUERY_STRING >> $Form_TMPDIR/queryPOST
}

Form.get()
{
	variable=$1
	
	if [ -z "$variable" ]
	then
		echo $REQUEST_URI
		exit
	fi
	
	echo $REQUEST_URI \
		| gawk 'BEGIN{RS="[&?]+"}{ split($0,arr,"="); if(arr[1]~"'"$variable"'"){ print arr[2]; exit } }' \
		| sed '{s/%2C/,/g;s/+/ /g}'
}

Form.post()
{
	variable=$1
	isFile=$2
	
	####################################################################
# # 	http://www.team2053.org/docs/bashcgi/postdata.html
# 	echo "REQUEST_METHOD ===>>> $REQUEST_METHOD" > /tmp/salida
# 	echo "SERVER_SOFTWARE ===>>> $SERVER_SOFTWARE" >> /tmp/salida
# 	echo "CONTENT_LENGTH ===>>> $CONTENT_LENGTH" >> /tmp/salida
# 	echo "QUERY_STRING_POST ===>>> $QUERY_STRING_POST" >> /tmp/salida
# 	
# 	tmp=`cat $Form_TMPDIR/queryPOST`
# 	# replace all + with whitespace and append %%
# 	t="${tmp//+/ }%%"
# 	while [ ${#t} -gt 0 -a "${t}" != "%" ]; do
# 		v="${v}${t%%\%*}" # digest up to the first %
# 		t="${t#*%}" # remove digested part
# 		# decode if there is anything to decode and if not at end of string
# 		if [ ${#t} -gt 0 -a "${t}" != "%" ]; then
# 			h=${t:0:2} # save first two chars
# 			t="${t:2}" # remove these
# 			v="${v}"`echo -e \\\\x${h}` # convert hex to special char
# 		fi
# 	done
# 	# return decoded string
# 	echo "Final ===>>> ${v}" >> /tmp/salida
	####################################################################
	
	if [ -z "$variable" ]
	then
		cat $Form_TMPDIR/queryPOST
		exit
	fi
	
	if [ "$isFile" = "file" ]
	then
		listFileName=( `
		gawk '
		($0~"filename="){
			for(i=1;i<=NF;i++){
				if($i~/filename=/){
					split($i,arr,"[\"=]+")
					print arr[2]
				}
			}
		}
		' $Form_TMPDIR/queryPOST` )
		
		listName=( `
		gawk '
		($0~"filename="){
			for(i=1;i<=NF;i++){
				if($i~/^name=/){
					split($i,arr,"[\"=]+")
					print arr[2]
				}
			}
		}
		' $Form_TMPDIR/queryPOST` )
		
		if [ "${#listFileName[@]}" -ge 1 ]
		then
			for(( i=0; i<${#listFileName[@]}; i++ ))
			do
				if [ ! -f "$Form_TMPDIR/${listFileName[$i]}" ]
				then
					gawk '
					BEGIN{
						loc=0;n=0
					}
					{
						if($0~/------WebKitForm/){
							loc=0
						}
							
						if(loc==1){
							lines[n]=$0
							n++
						}
						
						if( $0~/filename=\"'${listFileName[$i]}'\"/)
							loc=1
					}
					END{
						for(i=2;i<n-1;i++)
							print lines[i]
					}
					' $Form_TMPDIR/queryPOST > $Form_TMPDIR/${listFileName[$i]}
				fi
			done
			
			for(( i=0; i<${#listName[@]}; i++ ))
			do
				if [ "${listName[$i]}" = "$variable" ]
				then
					echo ${listFileName[$i]}
				fi
			done
		fi
	else
		gawk '
		BEGIN{
			loc=0;n=0
		}
		{
			if($0~/------WebKitForm/)
				loc=0
				
			if(loc==1){
				lines[n]=$0
				n++
			}
			
			if($0~/name=\"'$variable'\"/)
				loc=1
		}
		END{
			for(i=0;i<=n;i++)
				print lines[i]
		}
		' $Form_TMPDIR/queryPOST | tr -d '\n'| tr -d '\r'
	fi
}

Form.filePath()
{
	echo $Form_TMPDIR/$1
}

Form.fileContent()
{
	cat $Form_TMPDIR/$1
}

Form.destroy()
{
	rm -rf $Form_TMPDIR
}

