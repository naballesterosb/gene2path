#!/bin/bash

blastResultFile=$1
specie=$2

SCRATCH="/tmp/$$"

usage(){
cat > /dev/stdout << EOF
Usage:
	blastResult2geneID blastResultFile [ -l | specie ]
	
OPTIONS
	blastResultFile
		Fichero generado por blast2GO en el paso BLAST ( i.e. blastResult.xml )
		
	-l
		Lista a dos columnas todas las especies disponibles dentro del
		archivo blastResultFile y el número de proteinas encontradas por
		para cada especie en particular
		
	specie
		Muestra los resultados para proteinas homologas de la especie seleccionada
		obtenida desde la opción -l ( i.e. "Homo sapiens" )
EOF
}

findSpecies()
{
	grep "<Hit_def" $blastResultFile | sed '{s/^.*\[//g;s/\].*$//g}' | gawk '($1!~/<Hit_def/){ print $0 }' > $SCRATCH/.tmp
	
	gawk '
	{
		if( $0 in map ){
			map[$0] += 1
		}else{
			map[$0] = 1
		}
	}
	END{
		for( item in map ){
			itemRaw = item
			gsub( " ", "_", item )
			printf "%50s%7d\n", substr(item,0,50), map[itemRaw]
		}
	}
	' $SCRATCH/.tmp | sort -n -r -k 2 | sed 's/_/ /g'
	
	rm $SCRATCH/.tmp
}

getGeneIDFromProtIDAcc()
{
	local protID=$1
# 	local ID=$1
	
	jwget "http://www.ncbi.nlm.nih.gov/protein/$protID" > $SCRATCH/.tmp 2> /dev/null
	
	############################
	# Buscamos en More about the
	href=`grep -A10 "More about the" $SCRATCH/.tmp | grep "<a href=" | gawk 'BEGIN{FS="\""}{print $2}'`
	
	if [ -n "$href" ]
	then
		wget "www.ncbi.nlm.nih.gov/$href" -O $SCRATCH/.tmpPage 2> /dev/null
		
		genID=`grep -A2 "Gene ID:" $SCRATCH/.tmpPage 2> /dev/null | gawk 'BEGIN{FS="[:,]+"}{print $2;exit}' | sed -r '{s/[[:blank:]]+//g}'`
		genSym=`grep -A1 "Gene symbol" $SCRATCH/.tmpPage 2> /dev/null | tail -n1 | gawk 'BEGIN{FS="[<>]"}{print $3}'`
		if [ -z "$genSym" ]
		then
			genSym=`grep -A2 "noline.*Official" $SCRATCH/.tmpPage 2> /dev/null | tail -n1 | sed '{s/[<>]/ /g}' | gawk '{print $3}'`
		fi
		
		rm -rf $SCRATCH/.tmp $SCRATCH/.tmpPage
		
		echo "genID:$genID, genSym:$genSym"
		exit
	fi
	
	############################
	# Buscamos en Encoding mRNA
	href=`grep "Encoding mRNA" $SCRATCH/.tmp | head -n1 | gawk 'BEGIN{FS="\""}{print $4}'`
	
	if [ -n "$href" ]
	then
		wget "www.ncbi.nlm.nih.gov/$href" -O $SCRATCH/.tmpPage 2> /dev/null
		
		genBank=`grep "\"itemid\">GenBank:" $SCRATCH/.tmpPage 2> /dev/null \
			| sed 's/[<>]/ /g' \
			| gawk '{for(i=1;i<=NF;i++){if($i~/GenBank:/){ print $(i+1); exit }}}' \
			| sed '{s/[[:blank:]]+//g}'`
		
		rm -rf $SCRATCH/.tmp $SCRATCH/.tmpPage
		
		echo "genBank:$genBank"
		exit
	fi
	
	############################
	# Buscamos en Nucleotide
	href=`grep -n ">Nucleotide</a>" $SCRATCH/.tmp 2> /dev/null \
		| head -n1 | gawk 'BEGIN{FS="\""}{print $4}'`
		
	if [ -n "$href" ]
	then
		wget "www.ncbi.nlm.nih.gov/$href" -O $SCRATCH/.tmpPage 2> /dev/null
		
		genBank=`grep "\"itemid\">GenBank:" $SCRATCH/.tmpPage 2> /dev/null \
			| sed 's/[<>]/ /g' \
			| gawk '{for(i=1;i<=NF;i++){if($i~/GenBank:/){ print $(i+1); exit }}}' \
			| sed '{s/[[:blank:]]+//g}'`
		
		rm -rf $SCRATCH/.tmp $SCRATCH/.tmpPage
		
		echo "genBank:$genBank"
		exit
	fi

# 	http://www.ncbi.nlm.nih.gov/protein?Db=nuccore&DbFrom=protein&Cmd=Link&LinkName=protein_nuccore_mrna&IdsFromResult=225703278
	
# 	ID=`grep -A 10 "Reference sequence information" $SCRATCH/.tmp/www.ncbi.nlm.nih.gov/protein/*.html \
# 		| gawk 'BEGIN{RS="[[:blank:]]+"}($0~/href=\"http:\/\/www.ncbi.nlm.nih.gov\/nuccore\//){ gsub(/^.*\//,"",$0); gsub(/\"/,"",$0); print $0 }'`
		
# 	if [ -n "$ID" ]
# 	then
# 		ID=`grep "\"itemid\">GenBank:" $SCRATCH/.tmp/www.ncbi.nlm.nih.gov/nuccore/*.html \
# 			| sed 's/[<>]/ /g' \
# 			| gawk '{for(i=1;i<=NF;i++){if($i~/GenBank:/){ print $(i+1); exit }}}' \
# 			| sed '{s/[[:blank:]]+//g}'`
# 			
# 		if [ -n "$ID" ]
# 		then
# 			ID="genBank:$ID"
# 		fi
# 	else
# 		ID="genID:$genID  genSym:$genSym  genBank:$genBank"
# 	fi
	
# 	echo $ID
}


main()
{
	if [ -z "$2" ]
	then
		usage
		exit
	fi

	mkdir $SCRATCH

	if [ "$2" = "-l" ]
	then
		findSpecies
		rm -rf $SCRATCH
		exit
	fi

	gawk '
	BEGIN{
		loc=0
	}
	{
		if( $0~/<Iteration_query-def>/ ){
			line = $0
			gsub( "<Iteration_query-def>", "", line)
			gsub( "</Iteration_query-def>", "", line)
			
			split(line,lineArray,"[|:]")
			if( length(lineArray[2]) != 0 ){
				queryID = lineArray[2]
# 				print "queryID(line)* = ", line
# 				print "queryID* = ", lineArray[2]
			}else{
				split(line,lineArray,"[-]") #solo es para los nohit que nos pasaron, prob. no sea general
				queryID = lineArray[1]
# 				print "queryID(line) = ", line
# 				print "queryID = ", lineArray[1]
			}
		}
		
		if( $0~/<Hit_def>/ ){
			if( $0~/'"$specie"'/ ){
				line = $0
				gsub( "<Hit_def>", "", line)
				gsub( "</Hit_def>", "", line)
				gsub( "[[:blank:]]+", "_", line)
				
				mapDef[queryID] = line
				
				loc = 1
# 				print "located = ", line
			}
		}
		
		if( loc == 1 ){
			if( $0~/<Hit_accession>/ ){
				line = $0
				gsub( "<Hit_accession>", "", line)
				gsub( "</Hit_accession>", "", line)
				
				mapIDs[queryID] = line
# 				print "mapID = ", line
			}
			
			if( $0~/<Hsp_identity>/ ){
				line = $0
				gsub( "<Hsp_identity>", "", line)
				gsub( "</Hsp_identity>", "", line)
				
				mapIdent[queryID] = line
# 				print "mapIdent = ", line
			}
			
			if( $0~/<Hsp_align-len>/ ){
				line = $0
				gsub( "<Hsp_align-len>", "", line)
				gsub( "</Hsp_align-len>", "", line)
				
				mapLen[queryID] = line
# 				print "mapLen = ", line
			}
			
			if( $0~/<\/Hsp>/ ){
				loc = 0
# 				print "END"
			}
		}
	}
	END{
		for( queryID in mapIDs ){
			homol = 100.0*mapIdent[queryID]/mapLen[queryID]
			
			if( length(mapDef[queryID]) > 70 )
				printf "%-20s%-20s%-20.1f%-70s\n", queryID, mapIDs[queryID], homol, substr(mapDef[queryID],0,80)"..."
	# 			printf "%-20s%-20.1f%-100s\n", mapIDs[queryID], homol, substr(mapDef[queryID],0,100)"..."
			else
				printf "%-20s%-20s%-20.1f%-70s\n", queryID, mapIDs[queryID], homol, mapDef[queryID]
	# 			printf "%-20s%-20.1f%-100s\n", mapIDs[queryID], homol, mapDef[queryID]
		}
	}
	' $blastResultFile > $SCRATCH/.values

	printf "#%-14s%-15s%-15s%-15s%-15s%-15s%-15s%-6s%-70s\n" \
		"GenIDBase" "JCIDBeg" "JCIDEnd" "GenID" "GenSym" "GenBank" "protACC" "%h" "Prot.Description"

	cat $SCRATCH/.values | while read line
	do
		genIDBase=`echo $line | gawk '{ print $1 }'`
		protID=`echo $line | gawk '{ print $2 }'`
		homol=`echo $line | gawk '{ print $3 }'`
		protDesc=`echo $line | gawk '{ print $4 }'`
		JCIDBegin=`troutDict.sh $genIDBase | gawk '{ print $NF; exit }' | sed 's/USAGE://g'`
		
		IDRaw=`getGeneIDFromProtIDAcc $protID`
		genID=`echo $IDRaw | gawk 'BEGIN{FS="[[:blank:],:]+"}{for(i=1;i<=NF;i++) if($i=="genID") print $(i+1) }'`
		genSym=`echo $IDRaw | gawk 'BEGIN{FS="[[:blank:],:]+"}{for(i=1;i<=NF;i++) if($i=="genSym") print $(i+1) }'`
		genBank=`echo $IDRaw | gawk 'BEGIN{FS="[[:blank:],:]+"}{for(i=1;i<=NF;i++) if($i=="genBank") print $(i+1) }'`
		JCIDEnd=`troutDict.sh $genID | gawk '{ print $NF; exit }' | sed 's/USAGE://g'`
		
		if [ -z "$JCIDBegin" ]; then JCIDBegin="--"; fi
		if [ -z "$JCIDEnd" ]; then JCIDEnd="--"; fi
		if [ -z "$genID" ]; then genID="--"; fi
		if [ -z "$genSym" ]; then genSym="--"; fi
		if [ -z "$genBank" ]; then genBank="--"; fi
		
		printf "%-15s%-15s%-15s%-15s%-15s%-15s%-15s%-6s%-70s\n" \
			$genIDBase "$JCIDBegin" "$JCIDEnd" $genID $genSym $genBank $protID $homol $protDesc
	done
	
	rm $SCRATCH/.values
	rm -rf $SCRATCH
}

main $*
