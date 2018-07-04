#!/bin/bash

DICT_HOME=$GENE2PATH_HOME
DICT_FILE=$GENE2PATH_HOME/data/FILE.dict
FASTA_DIR=$GENE2PATH_HOME/data/fasta

suff=$$
IFILE=""
FASTA_FILE=""

WORKDIR=""

usage()
{
cat <<EOF
USAGE:
	troutDict.sh [ -ifile=filename | -vfile=filename ] [ -fasta ] [ -dictFile ] [ geneID1 geneID2 ... ]

	Este programa permite manipular de manera indiferente un gen teniendo cualquier identificador o ID del mismo,
	los IDs disponibles corresponden a:
		
		GenBank ID
		Entrez Gene ID (gi)
		JC ID
	
OPTIONS
	-ifile=filename
		Muestra las coincidencias de los genes através de sus IDs dentro del archivo "filename" 
				
	-vfile=filename
		Realiza el mismo trabajo que el -ifile, pero reporta todos los genes encontrados en el diccionario excepto los 
		genes que se colocan en la lista [ geneID1 geneID2 ... ] 
		
	-fasta
		Muestra los archivos .fasta de los genes de la lista [ geneID1 geneID2 ... ]
		
	-dictFile
		Muestra la ruta absoluta al fichero del diccionario.
		
	geneID1 geneID2 ...
		Lista de genes que se desean buscar. Si no se coloca ningún gen, el programa tomará por omisión todos los genes
		disponibles en el diccionario.
		
authors:
	Natalia A. Ballesteros ( nataliabal@cib.csic.es )
	Nestor F. Aguirre ( nfaguirrec@iff.csic.es )
EOF
}

findGene()
{
	local geneID=$1
	
	if [ -f /tmp/.fasta ]
	then
		findFasta $geneID
	elif [ -f /tmp/.ifile ]
	then
		findInFile $geneID
	else
		grep $geneID $DICT_FILE
	fi
}

findFasta()
{
	local geneID=$1
	
	for igene in `grep $geneID $DICT_FILE`
	do
		igene=`echo $igene | sed 's/^.*://g'`
		if [ -f "$FASTA_DIR/$igene.fasta" ]
		then
			cat $FASTA_DIR/$igene.fasta
			return
		fi
	done
}

findInFile()
{
	local geneID=$1
	
	for igene in `grep $geneID $DICT_FILE`
	do
		grep -n $geneID /tmp/.ifile > /tmp/.tmp$suff
		
		if [ -n "`cat /tmp/.tmp$suff | gawk '{print $1}'`" ]
		then
			echo "--------------------------------------------------------------------"
			echo "DICT: `grep $geneID $DICT_FILE | sed -E 's/[[:blank:]]+/ /g'`"
			echo "--------------------------------------------------------------------"
			cat /tmp/.tmp$suff
			break
		fi
		
		rm /tmp/.tmp$suff
	done
}

findNotInFile()
{
	cat $DICT_FILE | while read line
	do
		rex=`echo $line | sed '{s/^.*://g}' | sed -E '{s/[[:blank:]]+/\n/g}' | gawk '{printf $1"|"}' | sed 's/|$//g'`
		match=`grep -w -E "($rex)" /tmp/.vfile | gawk '{print $1}'`
		
		if [ -z "$match" ]
		then
# 			if [ -f .fasta ]
# 			then
				# @TODO Falta implementar que genere los fasta en busqueda inversa
# 				for igene in `gawk '{print $1}' $DICT_FILE`
# 				do
# 					igene=`echo $igene | sed 's/^.*://g'`
# 					findGene $igene
# 				done
# 
# 				findFasta $geneID
# 			else
				echo $line
# 			fi
		fi
	done
}

main()
{
	WORKDIR=$PWD
	pushd . > /dev/null 2> /dev/null
	cd $DICT_HOME
	
	if [ -z "$*" ]
	then
		usage
		exit
	fi
	
	searchAllGenes="T"
	
	rm -rf /tmp/.fasta /tmp/.ifile /tmp/.vfile
	for opt in $*
	do
		case `echo $opt | gawk 'BEGIN{FS="[=]"}{print $1}'` in
			"-h" | "--help")
				usage
				;;
			"-fasta")
				cat /dev/null > /tmp/.fasta
				;;
			"-ifile")
				cp $WORKDIR/`echo $opt | gawk 'BEGIN{FS="[=]"}{print $2}'` /tmp/.ifile
				;;
			"-vfile")
				cp $WORKDIR/`echo $opt | gawk 'BEGIN{FS="[=]"}{print $2}'` /tmp/.vfile
				;;
			"-dictFile")
				echo $DICT_FILE
				;;
			*)
				searchAllGenes="F"
				findGene $opt
				;;
		esac
	done
	
	if [ "$searchAllGenes" = "T" -a -f /tmp/.ifile ]
	then
		for igene in `gawk '{print $1}' $DICT_FILE`
		do
			igene=`echo $igene | sed 's/^.*://g'`
			findGene $igene
		done
	fi
	
	if [ -f /tmp/.vfile ]
	then
		findNotInFile
	fi
	
	rm -rf /tmp/.fasta /tmp/.ifile /tmp/.vfile

	popd > /dev/null 2> /dev/null
}

main $*
