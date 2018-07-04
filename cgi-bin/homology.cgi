#!/bin/bash

source ../gene2path.conf
source FormUtils.sh
source insertToTemplate.sh

# Form.get()
# {
# 	variable=$1
# 	echo $REQUEST_URI | gawk 'BEGIN{RS="[&?]+"}{ split($0,arr,"="); if(arr[1]~"'"$variable"'"){ print arr[2]; exit } }'
# }

getHomologyLine()
{
	local gene=$1
	local FORM_specieMult=$2
	local tmpFile=$3
	
	local gbID0=""
	
	gbID0=`troutDict.sh $gene | sed 's/[[:blank:]]+/\n/g' | gawk '($1~/gb/){ print $1 }' | sed 's/gb://g'`
	
	homology.sh -i $gbID0 -s $FORM_specieMult > $tmpFile
}

showHomologyLine()
{
	local tmpFile=$1
	
	local unigeneTrout=""
	local omy=""
	local gbID=""
	local protName=""
	local geneLd=""
	local geneID=""
	local geneJCID=""
	
	if [ -f $tmpFile -a -n "`cat $tmpFile`" ]
	then
		unigeneTrout=`cat $tmpFile | grep "UniGeneTrout" | gawk '{print $2}'`
		omy=`cat $tmpFile | grep "Omy" | gawk '{print $2}'`
		gbID=`cat $tmpFile | grep "gbID" | gawk '{print $2}'`
		protName=`cat $tmpFile | grep "protName" | sed 's/protName:/ /g'`
		geneLd=`cat $tmpFile | grep "ld" | gawk '{print $2}'`
		geneID=`cat $tmpFile | grep "geneID" | gawk '{print $2}'`
		
		geneJCID=`troutDict.sh $gbID | gawk '{print $NF}'`
		
		if [ -n "$geneID" ]
		then
# 					printf "%15s%15s%15s%15s%25s%15s    " $geneJCID $gbID $unigeneTrout $omy $geneID $geneLd
# 					echo "$protName<br>"
			
			echo "<tr>"
			echo "<td style=\"vertical-align: top; text-align: center;\">"
			echo "$geneJCID"
			echo "</td>"
			echo "<td style=\"vertical-align: top; text-align: center;\">"
			echo "$gbID"
			echo "</td>"
			echo "<td style=\"vertical-align: top; text-align: center;\">"
			echo "$unigeneTrout"
			echo "</td>"
			echo "<td style=\"vertical-align: top; text-align: center;\">"
			echo "$omy"
			echo "</td>"
			echo "<td style=\"vertical-align: top; text-align: center;\">"
			echo "$geneID"
			echo "</td>"
			echo "<td style=\"vertical-align: top; text-align: center;\">"
			echo "$geneLd"
			echo "</td>"
			echo "<td style=\"vertical-align: top; text-align: center; width: 40px;\">"
			echo "$protName" | sed '{s/_/ /g}'
			echo "</td>"
			echo "</tr>"
		fi
	fi
	
	rm -rf $tmpFile
}

echo "Content-type: text/html"
echo ""
templateTop homology.html

Form.init

if [ -z "`Form.post`" ]
then
	echo "<hr style=\"width: 100%; height: 1px;\">"
	echo "<b>Orthology</b>"
	echo "<hr style=\"width: 100%; height: 1px;\">"
	echo "<span style='font-family: monospace;'>"
	echo "<br>"
	
	templateContent homology.html
else
	FORM_searchType=`Form.post searchType`
	
	FORM_gbID=`Form.post gbID`
	FORM_list=`Form.post list`
	FORM_specie=`Form.post specie`
	
	FORM_geneList=`Form.post geneList`
	FORM_specieMult=`Form.post specieMult`
	
	FORM_fileB2G=`Form.post fileBlast2go "file"`
	FORM_getSpeciesB2G=`Form.post checkBoxGetSpeciesBlas2go`
	FORM_specieB2G=`Form.post textSpecieBlast2go`
	
	if [ "$FORM_searchType" = "individual" ]
	then
		if [ "$FORM_list" = "on" ]
		then
			echo "<hr style=\"width: 100%; height: 1px;\">"
			echo "<b>Homology</b>"
			echo "<hr style=\"width: 100%; height: 1px;\">"
			echo "<span style='font-family: monospace;'>"
			echo "<br>"
			
			echo "<span style='font-family: monospace;'>"
			homology.sh -i "$FORM_gbID" -l \
				| sed '{s/$/<br>/g}'
			echo "</span>"
		else
			echo "<hr style=\"width: 100%; height: 1px;\">"
			echo "<b>Homology</b>"
			echo "<hr style=\"width: 100%; height: 1px;\">"
			echo "<span style='font-family: monospace;'>"
			echo "<br>"
			
			echo "<span style='font-family: monospace;'>"
			homology.sh -i "$FORM_gbID" -s "$FORM_specie" \
				| sed 's/$/<br>/g' \
				| sed -r '{s/[[:alnum:]]+:/<b><font color=\"red\">&<\/font><\/b>/g}' \
				| sed '{s/'$FORM_specie'/<br><b>&<\/b>/g}'
			echo "</span>"
		fi
	elif [ "$FORM_searchType" = "collective" ]
	then
		echo "<hr style=\"width: 100%; height: 1px;\">"
		echo "<b>Homology</b>"
		echo "<hr style=\"width: 100%; height: 1px;\">"
		echo "<span style='font-family: monospace;'>"
		echo "<br>"
		
# 		echo "<span style='font-family: monospace;'>"
		
		echo "<table style=\"text-align: center; width: 100%;\" border=\"1\" cellpadding=\"5\" cellspacing=\"0\">"
		echo "<tbody>"
		
# 		echo "JC-ID     gb-IDtrout   UniGeneTrout            Dre  UniGene-rerio     %-homology    NameProtein" \
# 			| sed -r '{s/^/<tr><td style="vertical-align: center; text-align: center;">/g;s/$/<\/td><\/tr>/g}' \
# 			| sed -r '{s/[[:blank:]]{3,}/<\/td><td style="vertical-align: top;">/g}' \
# 			| sed '{s/JC-ID/<b>&<\/b>/g}' \
# 			| sed '{s/gb-IDtrout/<b>&<\/b>/g}' \
# 			| sed '{s/UniGeneTrout/<b>&<\/b>/g}'

		echo "<tr>"
		echo "<td style=\"vertical-align: center; text-align: center;\">"
		echo "<b>JC-ID</b>"
		echo "</td>"
		echo "<td style=\"vertical-align: center; text-align: center;\">"
		echo "<b>gb-IDtrout</b>"
		echo "</td>"
		echo "<td style=\"vertical-align: center; text-align: center;\">"
		echo "<b>UniGeneTrout</b>"
		echo "</td>"
		echo "<td style=\"vertical-align: center; text-align: center;\">"
		echo "<b>Dre</b>"
		echo "</td>"
		echo "<td style=\"vertical-align: center; text-align: center;\">"
		echo "<b>UniGene-rerio</b>"
		echo "</td>"
		echo "<td style=\"vertical-align: center; text-align: center;\">"
		echo "<b>%-homology</b>"
		echo "</td>"
		echo "<td style=\"vertical-align: center; text-align: center;\">"
		echo "<b>NameProtein</b>"
		echo "</td>"
		echo "</tr>"
		
		startTime=`date "+%s"`
		
		#-----------------------------------------------------------------------
# 		genes=( `echo $FORM_geneList | sed '{s/+/ /g;s/%0D%0A/ /g}'` )
# 		
# 		for (( i=0; i<=${#genes[@]}; i++ ))
# 		do
# 			getHomologyLine ${genes[$i]} $FORM_specieMult "/tmp/.output-th$i"
# 			showHomologyLine "/tmp/.output-th$i"
# 		done
		
		nThreads="10"
		genes=( `echo $FORM_geneList | sed '{s/+/ /g;s/%0D%0A/ /g}'` )
		
		ij="0"
		for (( i=0; i<=$(( ${#genes[@]}/$nThreads-1 )); i++ ))
		do
			for j in `seq 0 $nThreads`
			do
				ij=$(( $j+$nThreads*$i ))
				getHomologyLine ${genes[$ij]} $FORM_specieMult "/tmp/.output-th$ij" &
			done
			
			wait
			
			for j in `seq 0 $nThreads`
			do
				ij=$(( $j+$nThreads*$i ))
				
				showHomologyLine "/tmp/.output-th$ij"
			done
		done

		if (( $ij < ${#genes[@]} ))
		then
			for (( i=$ij; i<${#genes[@]}; i++ ))
			do
				getHomologyLine ${genes[$i]} $FORM_specieMult "/tmp/.output-thf$i" &
			done
			
			wait
			
			for (( i=$ij; i<${#genes[@]}; i++ ))
			do
				showHomologyLine "/tmp/.output-thf$i"
			done
		fi
		#-----------------------------------------------------------------------
		
		echo "</tbody>"
		echo "</table>"
		
		endTime=`date "+%s"`
		elapsedTime=$(( $endTime-$startTime ))
		echo "Time elapsed: $(( $elapsedTime / 3600 ))h $(( ( $elapsedTime / 60 ) % 60 ))m $(( $elapsedTime % 60 ))s"

# 		echo "</span>"
		
	elif [ "$FORM_searchType" = "blast2go" ]
	then
		if [ "$FORM_getSpeciesB2G" = "on" ]
		then
			echo "<table style=\"text-align: center; width: 40%; margin-left: auto; margin-right: auto; \" border=\"1\" cellpadding=\"2\" cellspacing=\"2\">"
			echo "<tbody>"
			
			echo "<tr>"
			echo "<td style=\"text-align: left;\"><span style=\"font-weight: bold;\">Specie</span></td>"
			echo "<td style=\"text-align: left;\"><span style=\"font-weight: bold;\">Counts</span></td>"
			echo "</tr>"
			
			blastResult2geneID.sh `Form.filePath $FORM_fileB2G` -l \
				| sed -r '{s/[[:blank:]]+[[:digit:]]+$/=====&/g}' \
				| sed -r '{s/^/<tr><td style=\"text-align: left;\">/g;s/$/<\/td><\/tr>/g}' \
				| sed -r '{s/=====/<\/td><td>/g}'
	# 			| sed '{s/$/<br>/g}'
				
			echo "</tbody>"
			echo "</table>"
		else
			echo "<small><small><span style=\"font-family: monospace;\">"
			echo "<table style=\"text-align: center; width: 40%; margin-left: auto; margin-right: auto; \" border=\"1\" cellpadding=\"2\" cellspacing=\"0\">"
			echo "<tbody>"
			
			echo "<tr>"
			echo "<td style=\"text-align: left; vertical-align: top; width: 10%;\"><span style=\"font-weight: bold;\">GenIDBase</span></td>"
			echo "<td style=\"text-align: left; vertical-align: top; width: 10%;\"><span style=\"font-weight: bold;\">GenID</span></td>"
			echo "<td style=\"text-align: left; vertical-align: top; width: 10%;\"><span style=\"font-weight: bold;\">GenSym</span></td>"
			echo "<td style=\"text-align: left; vertical-align: top; width: 10%;\"><span style=\"font-weight: bold;\">GenBank</span></td>"
			echo "<td style=\"text-align: left; vertical-align: top; width: 10%;\"><span style=\"font-weight: bold;\">protACC</span></td>"
			echo "<td style=\"text-align: left; vertical-align: top; width: 10%;\"><span style=\"font-weight: bold;\">%h</span></td>"
			echo "<td style=\"text-align: left; vertical-align: top; width: 40%;\"><span style=\"font-weight: bold;\">Prot.Description</span></td>"
			echo "</tr>"
			
			blastResult2geneID.sh `Form.filePath $FORM_fileB2G` "$FORM_specieB2G" \
				| sed -r '{/^.*#/d}' \
				| gawk '{print $1"   "$4"   "$5"   "$6"   "$7"   "$8"   "$9}' \
				| sed -r '{s/^/<tr><td style="text-align: left; vertical-align: top; width: 20%;">/g;s/$/<\/td><\/tr>/g}' \
				| sed -r '{s/[[:blank:]]{3,}/<\/td><td style="text-align: left; vertical-align: top; width: 20%;">/g}' \
				| sed '{s/_/ /g}'
				
# 				| sed '{s/$/<br>/g}' \
				
			echo "</tbody>"
			echo "</table>"
			echo "</span></small></small>"
		fi

		echo "<br>"
	fi
	echo "<br>"
fi

templateBottom homology.html

Form.destroy

