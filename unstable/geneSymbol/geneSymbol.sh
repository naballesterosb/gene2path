#!/bin/bash 

symbolFromNUCCORE(){
	ID=$1
	
	rm -rf .tmp
	mkdir .tmp
	httrack www.ncbi.nlm.nih.gov/nuccore/$ID -O .tmp > /dev/null
	
	if [ -f .tmp/www.ncbi.nlm.nih.gov/nuccore/$ID.html ]
	then
		link=`grep -A10 "More about the" .tmp/www.ncbi.nlm.nih.gov/nuccore/$ID.html | grep "<a href=" | awk 'BEGIN{FS="\""}{print $2}'`
	else
		return
	fi
	
# 	title=`grep -A1 "class=\"rprtheader\"" .tmp/www.ncbi.nlm.nih.gov/nuccore/$ID.html | tail -n1 | awk 'BEGIN{FS="[<>]"}{print $3}' | sed 's/ /_/g'`
# 	
# 	if [ -n "$title" ]
# 	then
# 		echo "$title     `troutDict.sh $ID`"
# 	fi
	
# 	wget $link -O .tmpPage > /dev/null 2> /dev/null
# 	
# 	if [ -f .tmpPage ]
# 	then
# 		symbol=`grep -A1 "Gene symbol" .tmpPage | tail -n1 | awk 'BEGIN{FS="[<>]"}{print $3}'`
# 		descrip=`grep -A1 "Gene description" .tmpPage | tail -n1 | awk 'BEGIN{FS="[<>]"}{print $3}' | sed 's/ /_/g'`
# 
# 		echo "$symbol        $descrip     `troutDict.sh $ID`"
# 	fi

	rm -rf .tmpPage .tmp
}

symbolFromNUCEST(){
	local ID=$1
	
	wget http://www.ncbi.nlm.nih.gov/nucest/$ID -O salida.html -o /dev/null
	
	link=`grep "?report=fasta" salida.html \
		| awk '{ for(i=1;i<=NF;i++) if($i~"^href="){ print $i } }' \
		| sed '{s/^href=\"//g;s/"//g}'`
		
	link="http://www.ncbi.nlm.nih.gov/$link"
# 	rm salida.html
	
	echo "$link"
	rm -rf .tmp
	mkdir .tmp
	httrack -g $link -O .tmp > /dev/null
	
# 	httrack http://www.ncbi.nlm.nih.gov/nucest/$ID -O .tmp > /dev/null
	
# 	if [ -f .tmp/www.ncbi.nlm.nih.gov/nucest/$ID.html ]
# 	then
# 		link=`grep -A10 "More about the" .tmp/www.ncbi.nlm.nih.gov/nucest/$ID.html | grep "<a href=" | awk 'BEGIN{FS="\""}{print $2}'`
# 	else
# 		return
# 	fi
# 	
# 	wget $link -O .tmpPage > /dev/null 2> /dev/null
# 	
# 	if [ -f .tmpPage ]
# 	then
# 		symbol=`grep -A2 "Official" .tmpPage | grep -A1 "Symbol" | tail -n1 | awk 'BEGIN{FS="[<>]"}{print $3}'`
# 		fullName=`grep -A2 "Official" .tmpPage | grep -A1 "Full Name" | tail -n1 | awk 'BEGIN{FS="[<>]"}{print $3}' | sed 's/ /_/g'`
# 
# 		echo "$symbol     $fullName     `troutDict.sh $ID`"
# 	fi
	
# 	rm -rf salida.html
# 	rm -rf .tmpPage .tmp
}

main(){
	symbolFromNUCEST $1
# 	dataBase=$1
# 	
# # 	genList=`ls ../*.fasta | sed "{s/..\///g;s/.fasta//g}"`
# # 	genList=`awk '{print $3}' ../FILE.dict`
# 	genList=`cat todosLosTC`
# 	
# 	for gene in $genList
# 	do
# 		labels=`troutDict.sh $gene`
# 		
# 		echo -n "Searching for $gene " > /dev/stderr
# 		
# 		if [ "$dataBase" = "nuccore" ]
# 		then
# 			echo -n "in nuccore " > /dev/stderr
# 		elif [ "$dataBase" = "nucest" ]
# 		then
# 			echo -n "in nucest " > /dev/stderr
# 		fi
# 		
# 		located="0"
# 		for label in $labels
# 		do
# 			echo -n "." > /dev/stderr
# 			
# 			if [ "$dataBase" = "nuccore" ]
# 			then
# 				output=`symbolFromNUCCORE $label`
# 			elif [ "$dataBase" = "nucest" ]
# 			then
# 				output=`symbolFromNUCEST $label`
# 			fi
# 			
# 			if [ -n "$output" ]
# 			then
# 				located="1"
# 				echo $output
# 				echo " OK" > /dev/stderr
# 				break
# 			fi
# 			
# 			echo -n ":" > /dev/stderr
# 		done
# 		
# 		if [ "$located" -eq "0" ]
# 		then
# 			echo " Failed" > /dev/stderr
# 		fi
# 		
# 	done
}

main $*

