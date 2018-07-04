#!/bin/bash

source ../gene2path.conf
source insertToTemplate.sh

Form.get()
{
	variable=$1
	echo $REQUEST_URI | gawk 'BEGIN{RS="[&?]+"}{ split($0,arr,"="); if(arr[1]~"'"$variable"'"){ print arr[2]; exit } }'
}

echo "Content-type: text/html"
echo ""
templateTop pathways.html

if [ "$REQUEST_URI" = "/cgi-bin/gene2path/pathways.cgi" ]
then
	echo "<hr style=\"width: 100%; height: 1px;\">"
	echo "<b>KEGG Pathways</b>"
	echo "<hr style=\"width: 100%; height: 1px;\">"
	echo "<span style='font-family: monospace;'>"
	echo "<br>"

	templateContent pathways.html
else
	FORM_searchType=`Form.get searchType`
	
	FORM_geneID=`Form.get geneID`
	FORM_checkBoxListKEGG=`Form.get checkBoxListKEGG`
	FORM_checkBoxDetailsKEGG=`Form.get checkBoxDetailsKEGG`
	FORM_specie=`Form.get specie`
	
	FORM_geneList=`Form.get geneList`
	FORM_specieMult=`Form.get specieMult`
	
	if [ "$FORM_searchType" = "individual" ]
	then
		if [ "$FORM_checkBoxListKEGG" = "on" ]
		then
			echo "<hr style=\"width: 100%; height: 1px;\">"
			echo "<b>KEGG Pathways</b>"
			echo "<hr style=\"width: 100%; height: 1px;\">"
			echo "<span style='font-family: monospace;'>"
			echo "<br>"
			
			echo "<span style='font-family: monospace;'>" > /tmp/content.txt
			
			if [ -z "$FORM_specie" ]
			then
				KEGG.sh -i "$FORM_geneID" -l \
					| sed -r '{s/^[[:alnum:]]+[[:blank:]]*$/<br><b>&<\/b>/g}' >> /tmp/content.txt
			else
				KEGG.sh -i "$FORM_geneID" -s $FORM_specie -l \
					| sed -r '{s/^[[:alnum:]]+[[:blank:]]*$/<br><b>&<\/b>/g}' >> /tmp/content.txt
			fi
				
			echo "</span>" >> /tmp/content.txt
			
			cat /tmp/content.txt
			
		elif [ "$FORM_checkBoxDetailsKEGG" = "on" ]
		then
			echo "<hr style=\"width: 100%; height: 1px;\">"
			echo "<b>KEGG Pathways</b>"
			echo "<hr style=\"width: 100%; height: 1px;\">"
			echo "<span style='font-family: monospace;'>"
			echo "<br>"
			
			if [ -z "$FORM_specie" ]
			then
				KEGG.sh -i "$FORM_geneID" -d \
					| sed -r '{s/^[[:alnum:]]+[[:blank:]]*$/<br><b>&<\/b>/g}' \
					| sed -r '{s/^.*: /<font color=\"red\">&<\/font>/g}' \
					| sed '{s/$/<br>/g}'
			else
				KEGG.sh -i "$FORM_geneID" -s $FORM_specie -d \
					| sed -r '{s/^[[:alnum:]]+[[:blank:]]*$/<br><b>&<\/b>/g}' \
					| sed -r '{s/^.*: /<font color=\"red\">&<\/font>/g}' \
					| sed -r '{s/http:.*[[:blank:]]*$/<a href=\"&\">&<\/a>/g}' \
					| sed '{s/$/<br>/g}'
			fi
				
			echo "</span>"
		fi
	elif [ "$FORM_searchType" = "collective" ]
	then
		echo "<hr style=\"width: 100%; height: 1px;\">"
		echo "<b>KEGG Pathways</b>"
		echo "<hr style=\"width: 100%; height: 1px;\">"
		echo "<span style='font-family: monospace;'>"
		echo "<br>"
		
		echo "<span style='font-family: monospace;'>"
		
#                 echo "<b>"
#                 echo "#         JC-ID     gb-IDtrout   UniGeneTrout            Dre  UniGene-rerio     %-homology    NameProtein<br>"
#                 echo "</b>"
                
		suff=$$
		echo "" > /tmp/.output$suff
		for geneID in `echo $FORM_geneList | sed 's/+/ /g'`
		do
			for kegg in `KEGG.sh -i $geneID -s $FORM_specieMult -l`
			do
				printf "%15s%15s\n" $geneID $kegg >> /tmp/.output$suff
			done
		done
		
		gawk '
		{
			if( $2 in map ){
				map[$2] = map[$2]"   "$1
			}else{
				map[$2] = $2"   "$1
			}
		}
		END{
			for( item in map )
				print map[item]
		}
		' /tmp/.output$suff > /tmp/.values$suff
		rm /tmp/.output$suff
		
		echo "<br>"
		
		while read line
		do
			keggID=`echo $line | sed 's/[[:blank:]]/+/g'`
			
			if [ -n "$keggID" ]
			then
				path="http://www.kegg.jp/kegg-bin/show_pathway?$keggID"
				echo "$line" | gawk '{ printf "<a href=\"'$path'\">"$1"</a> " }'
				echo "$line" | gawk 'BEGIN{RS="[[:blank:]]+"}(NR>1){ printf $1"  " }'
				echo "<br>"
# 				echo "<a href=\"$path\">Image</a><br><br>"
			fi
		done < /tmp/.values$suff
		
		echo "</span>"
	fi
	
	echo "<br>"
fi

templateBottom pathways.html
