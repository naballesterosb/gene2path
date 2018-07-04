#!/bin/bash

source ../gene2path.conf
source FormUtils.sh
source insertToTemplate.sh

echo "Content-type: text/html"
echo ""
templateTop dictionary.html

Form.init

if [ -z "`Form.post genesIDList`" -a -z "`Form.post genesIDListFile "file"`" ]
then
	echo "<hr style=\"width: 100%; height: 1px;\">"
	echo "<b>Dictionary</b>"
	echo "<hr style=\"width: 100%; height: 1px;\">"
	
	templateContent dictionary.html
else
	FORM_genesIDList=`Form.post genesIDList`
# 	FORM_genesIDListFile=`Form.post genesIDListFile "file"`
	FORM_genesIDListFile=`Form.post "file"`
	FORM_fasta=`Form.post fasta`
	
# 	echo "FORM_genesIDList=$FORM_genesIDList<br>"
# 	echo "FORM_genesIDListFile=$FORM_genesIDListFile<br>"
# 	echo "FORM_fasta=$FORM_fasta<br>"
	
# 	if [[ "$FORM_fasta" =~ "on" ]]
	if [ "$FORM_fasta" = "on" ]
	then
		echo "<hr style=\"width: 100%; height: 1px;\">"
		echo "<b>Dictionary</b>"
		echo "<hr style=\"width: 100%; height: 1px;\">"
		echo "<span style='font-family: monospace;'>"
		
		echo "$FORM_genesIDListFile" > /tmp/salida2
		Form.fileContent $FORM_genesIDListFile >> /tmp/salida2
		output=""
		if [ -n "$FORM_genesIDListFile" ]
		then
			output=`troutDict.sh -fasta `Form.fileContent $FORM_genesIDListFile` | sed 's/$/<br>/g'`
			
			# Si el gene no esta en el diccionario de trucha se busca en la web con el NCBI tools
			if [ -z "$output" ]
			then
				output=`getFasta.sh `Form.fileContent $FORM_genesIDListFile` | sed 's/$/<br>/g'`
			fi
		else
			output=`troutDict.sh -fasta $FORM_genesIDList | sed 's/$/<br>/g'`
			
			# Si el gene no esta en el diccionario de trucha se busca en la web con el NCBI tools
			if [ -z "$output" ]
			then
				output=`getFasta.sh $FORM_genesIDList | sed 's/$/<br>/g'`
			fi
		fi
		
		echo $output \
			| sed 's/<br>/<br>\n/g' \
			| gawk '{if($1~/^>/) print "<font size=\"+1\" color=\"red\">"$0"</font>"; else print $0 }'
		
		echo "</span>"
	else
		echo "<hr style=\"width: 100%; height: 1px;\">"
		echo "<b>Dictionary</b>"
		echo "<hr style=\"width: 100%; height: 1px;\">"
		echo "<font size='+1'><span style='font-family: monospace;'>"
		
		output=""
		if [ -n "$FORM_genesIDListFile" ]
		then
			output=`troutDict.sh `Form.fileContent $FORM_genesIDListFile` | sed 's/$/<br>/g'`
			
			# Si el gene no esta en el diccionario de trucha se busca en la web con el NCBI tools
			if [ -z "$output" ]
			then
				output=`geneSymbol.sh `Form.fileContent $FORM_genesIDListFile` | sed 's/$/<br>/g'`
			fi
		else
			output=`troutDict.sh $FORM_genesIDList | sed 's/$/<br>/g'`
					
			# Si el gene no esta en el diccionario de trucha se busca en la web con el NCBI tools
			if [ -z "$output" ]
			then
				output=`geneSymbol.sh $FORM_genesIDList | sed 's/$/<br>/g'`
			fi
		fi
		
		echo $output \
			| sed -r '{s/[[:alnum:]]+:/<b><font color=\"red\">&<\/font><\/b>/g}'
		
		echo "</span></font>"
	fi
	echo "<br>"
fi

templateBottom dictionary.html

Form.destroy

