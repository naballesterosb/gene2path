#!/bin/bash

source ../gene2path.conf
source FormUtils.sh
source insertToTemplate.sh

echo "Content-type: text/html"
echo ""
templateTop microarray.html

Form.init

if [ -z "`Form.post file1a "file"`" -a -z "`Form.post file1b "file"`" ]
then
	echo "<hr style=\"width: 100%; height: 1px;\">"
	echo "<b>Microarray</b>"
	echo "<hr style=\"width: 100%; height: 1px;\">"
	
	templateContent microarray.html
else
	FORM_cutoff=`Form.post cutoff`
	
	inputFile="$Form_TMPDIR/inputFile.txt"
	inputSignals="$Form_TMPDIR/signals.txt"
	inputControls="$Form_TMPDIR/controls.txt"
	
	echo "" > $inputFile
	echo "" > $inputSignals
	echo "" > $inputControls
	
	for(( i=1; i<30; i++ ))
	do
		FORM_fileA=`Form.post file${i}a "file"`
		FORM_signalA=`Form.post checkboxSignal${i}a`
		FORM_controlA=`Form.post checkboxControl${i}a`
		
		mv $Form_TMPDIR/$FORM_fileA $Form_TMPDIR/$FORM_fileA.old
# 		gawk '( $0~/JC/ || $0~/FEATURES/ ){ print $0 }' $Form_TMPDIR/$FORM_fileA.old | sort -k 7 > $Form_TMPDIR/$FORM_fileA
		gawk '( $0~/JC/ ){ print $0 }' $Form_TMPDIR/$FORM_fileA.old | sort -k 7 > $Form_TMPDIR/$FORM_fileA.tmp
		grep "FEATURES" $Form_TMPDIR/$FORM_fileA.old > $Form_TMPDIR/$FORM_fileA
		cat $Form_TMPDIR/$FORM_fileA.tmp >> $Form_TMPDIR/$FORM_fileA
		
		FORM_fileB=`Form.post file${i}b "file"`
		FORM_signalB=`Form.post checkboxSignal${i}b`
		FORM_controlB=`Form.post checkboxControl${i}b`
		
		mv $Form_TMPDIR/$FORM_fileB $Form_TMPDIR/$FORM_fileB.old
# 		gawk '( $0~/JC/ || $0~/FEATURES/ ){ print $0 }' $Form_TMPDIR/$FORM_fileB.old | sort -k 7 > $Form_TMPDIR/$FORM_fileB
		gawk '( $0~/JC/ ){ print $0 }' $Form_TMPDIR/$FORM_fileB.old | sort -k 7 > $Form_TMPDIR/$FORM_fileB.tmp
		grep "FEATURES" $Form_TMPDIR/$FORM_fileB.old > $Form_TMPDIR/$FORM_fileB
		cat $Form_TMPDIR/$FORM_fileB.tmp >> $Form_TMPDIR/$FORM_fileB
		
		if [ -z "$FORM_fileA" ]
		then
			break
		fi
		
		if [ "$FORM_signalA" = "on" ]
		then
			echo "$Form_TMPDIR/$FORM_fileA" >> $inputSignals
		elif [ "$FORM_controlA" = "on" ]
		then
			echo "$Form_TMPDIR/$FORM_fileA" >> $inputControls
		fi
		
		if [ "$FORM_signalB" = "on" ]
		then
			echo "$Form_TMPDIR/$FORM_fileB" >> $inputSignals
		elif [ "$FORM_controlB" = "on" ]
		then
			echo "$Form_TMPDIR/$FORM_fileB" >> $inputControls
		fi
	done
	
	echo "TITLE" >> $inputFile
	echo "prueba" >> $inputFile
	echo "" >> $inputFile
	echo -n "SIGNAL" >> $inputFile
	cat $inputSignals >> $inputFile
	echo "" >> $inputFile
	echo -n "CONTROL" >> $inputFile
	cat $inputControls >> $inputFile
	echo "" >> $inputFile
	
	echo "<table style=\"text-align: center; width: 40%;\" border=\"1\" cellpadding=\"2\" cellspacing=\"2\">"
	echo "<tbody>"

	microarray.py $inputFile $FORM_cutoff \
		| sed -r '{s/^.*#//}' \
		| sed -r '{s/^/<tr><td style="vertical-align: center; text-align: center;">/g;s/$/<\/td><\/tr>/g}' \
		| sed -r '{s/[[:blank:]]{3,}/<\/td><td style="vertical-align: top;">/g}' \
		| sed '{s/GeneID/<b>&<\/b>/g}' \
		| sed '{s/p-value/<b>&<\/b>/g}' \
		| sed '{s/t-test/<b>&<\/b>/g}'
		
	echo "</tbody>"
	echo "</table>"
	
	echo "<br>"
fi

templateBottom microarray.html

Form.destroy
