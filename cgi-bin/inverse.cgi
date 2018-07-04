#!/bin/bash

source ../gene2path.conf
source FormUtils.sh
source insertToTemplate.sh

echo "Content-type: text/html"
echo ""
templateTop inverse.html

Form.init

if [ "`Form.get`" = "/cgi-bin/gene2path/inverse.cgi" ]
then
	echo "<hr style=\"width: 100%; height: 1px;\">"
	echo "<b>Reverse search</b>"
	echo "<hr style=\"width: 100%; height: 1px;\">"
	echo "<span style='font-family: monospace;'>"
	echo "<br>"
	
	templateContent inverse.html
else
	FORM_keggId=`Form.get keggId`
	FORM_getFasta=`Form.get getFasta`
	FORM_specie=`Form.get specie`
	
	suff="/tmp/$$"
	mkdir $suff
	KEGG.sh -k $FORM_keggId -s $FORM_specie -o $suff
	
	echo "<br>"
	echo "<div align=\"center\">"
	echo "<a href=\"http://www.genome.jp/kegg-bin/show_pathway?$FORM_keggId\">"
	echo "<img width=\"640\" height=\"564\" align=\"middle\" src=\"http://www.genome.jp/kegg/pathway/hsa/$FORM_keggId.png\">"
	echo "</a>"
	echo "</div>"
	echo "<br>"
	echo "<br>"
	
	echo "<span style=\"font-family: monospace;\">"
	echo "<div align=\"center\">"
	echo "<table style=\"text-align: center; width: 20%;\" border=\"1\" cellpadding=\"5\" cellspacing=\"0\">"
	echo "<tbody>"
	
	cat $suff/$FORM_keggId.dat \
		| sed -r '{s/^[[:blank:]]+//g;s/[[:blank:]]+$//g}' \
		| sed -r '{s/^/<tr><td style="vertical-align: center; text-align: center;">/g;s/$/<\/td><\/tr>/g}' \
		| sed -r '{s/==>/<\/td><td style="vertical-align: center; text-align: center;">/g}' \
		| sed -r '{s/[[:blank:]]{3,}/<\/td><td style="vertical-align: top;">/g}' \
		| sed -r '{s/[-]{9,}/<\/td><td>/g}' \
		| sed '1i\<td><\/td><td><\/td>' \
		| sed 's/<tr><td style=\"vertical-align: center; text-align: center;\"><\/td><td><\/td><\/tr>/<tr><td style=\"vertical-align: center; text-align: center; background-color: rgb(255, 255, 102);\"><\/td><td><\/td><\/tr>/g' \
		| sed -r 's/<td><\/td>/<td style=\"background-color: rgb(255, 255, 102);\"><\/td>/g'
	
	echo "</tbody>"
	echo "</table>"
	echo "</div>"
	echo "</span>"
		
	echo "<br>"
	echo "<br>"
	
	if [ "$FORM_getFasta" = "on" ]
	then
		cat $suff/$FORM_keggId.fasta \
			| gawk '{if($1~/^>/) print "<font size=\"+1\" color=\"red\">"$0"</font>"; else print $0 }' \
			| sed '{s/$/<br>/g}'
			
		rm -rf $suff
	fi
	
	echo "<br>"
	rm -rf $suff
fi

templateBottom inverse.html

Form.destroy
