#!/bin/bash

usage()
{
cat << EOF
	Usage:

	Permite bajar el archivo fasta correspondiente dandole el genbankID access o el est
	almacena la lista de los genes que no se pudieron bajar en la fichero "log" y los
	si se bajaron se genera una archivo con el mismo nobre pero .fasta y tambien se adicionan
	al final del archivo All.fasta
	
	$ geneBankID2Fasta.sh ID1 ID2 ...

	requerimientos
	sudo apt-get install ncbi-tools-bin
	sudo apt-get install sgrep
EOF
}

getFasta()
{
	local geneID=$1
	
	echo $geneID | gbseqget > /tmp/.xml-$$
	
	echo -n ">"
	cat /tmp/.xml-$$ | sgrep -o "%r" -N '"<GBSeqid>" __ "</GBSeqid>"'
	echo -n "| "
	cat /tmp/.xml-$$ | \
		sgrep -o "%r\n" '"<GBSeq_definition>" __ "</GBSeq_definition>"'
	cat /tmp/.xml-$$ | \
		sgrep -o "%r" '"<GBSeq_sequence>" __ "</GBSeq_sequence>"' \
		| tr '[:lower:]' '[:upper:]' \
		| fold -w 70
		
	rm /tmp/.xml-$$
}


main(){
	nGenes=$#
	
	if (( "$nGenes" == 0 ))
	then
		usage
		exit 0
	fi
	
	for geneID in $*
	do
		getFasta $geneID
		echo ""
	done
}

main $*
