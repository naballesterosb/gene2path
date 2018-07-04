#!/bin/bash

ifile=$1 # Archivo donde cada palabra es un gene a buscar
specie=$2 # ejemplo dre
osuffix=$3 # directorio para los archivos de salida
nThreads=10

usage(){
cat > /dev/stdout << EOF
Usage:
# 	KEGGMulti.sh [ -i geneID [-s specie_prefix] [-l] [-d] ] [ -k keggID [-s specie_prefix] [-c] ] -o oprefix
# 	
# OPTIONS
# 	-i geneID
# 		Gene ID ( i.e. 9575 )
# 		
# 	-l
# 		Lista los KEGGs
# 		
# 	-d
# 		Lista los KEGGs con detalles
# 		
# 	-s specie_prefix
# 		Prefijo para la especie
# 		( default = hsa )
# 		
# 	-k keggID
# 		Retorna el archivo png del kegg asociado al id keggID
# 	
# 	-c
# 		Activa el flag: solo baja keggs coloreados
# 		
# 	-o oprefix
# 		Ruta para los archivos de salida
EOF
}

if [ -z "$osuffix" ]
then
	osuffix="."
fi

if [ ! -d "$osuffix" ]
then
	mkdir $osuffix
fi

suff=$$

getKEGGs()
{
	local geneID=$1
	local specie=$2
	
	cat /dev/null > .$geneID.dat
	for kegg in `KEGG.sh -i $geneID -s $specie -l`
	do
		printf "%15s%15s\n" $geneID $kegg >> .$geneID.dat
	done
}

# Obtiene la lista a dos columnas de los KEGG a los que pertenece cada GEN
# # genesID=( `cat $ifile` )
# # 
# # for (( i=0; i<=$(( ${#genesID[@]}/$nThreads-1 )); i++ ))
# # do
# # 	echo -n "Running genes ` seq -s " " $(( 1+$nThreads*$i )) $(( $nThreads+$nThreads*$i )) ` ... "
# # 	
# # 	for j in `seq 1 $nThreads`
# # 	do
# # 		ij=$(( $j+$nThreads*$i ))
# # 		getKEGGs ${genesID[$ij]} $specie &
# # 	done
# # 	
# # 	wait
# # 	
# # 	for j in `seq 1 $nThreads`
# # 	do
# # 		ij=$(( $j+$nThreads*$i ))
# # 		
# # 		if [ -f .${genesID[$ij]}.dat ]
# # 		then
# # 			cat .${genesID[$ij]}.dat >> .values1$suff
# # 			rm .${genesID[$ij]}.dat
# # 		fi
# # 	done
# # 	
# # 	echo "OK"
# # done
# # 
# # ij=$(( $ij+1 ))
# # if (( $ij < ${#genesID[@]} ))
# # then
# # 	for (( i=$ij; i<=${#genesID[@]}; i++ ))
# # 	do
# # 		echo -n "Running gene $i ... "
# # 		KEGG.sh -i ${genesID[$i]} -s $specie -c -o $osuffix >> .values1$suff
# # 		echo "OK"
# # 	done
# # fi

cat /dev/null > .values1$suff
for geneID in `cat $ifile`
do
	for kegg in `KEGG.sh -i $geneID -s $specie -l`
	do
		printf "%15s%15s\n" $geneID $kegg >> .values1$suff
	done
done

# Se organizan los datos para que en cada fila que un gene y todos los KEGG en que estan involucrados
awk '
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
' .values1$suff > .values2$suff
rm .values1$suff

cp .values2$suff $osuffix/pathway2gene.dat

# Si hay filas con mas de 30 KEGGs las parte en dos
sgroup=30
awk '
BEGIN{
        sgroup='$sgroup'
}
{
        if( NF>=sgroup ){
                for( i=1; i<(NF-1)/sgroup; i++ ){
                        printf $1"  "
                        for( j=2+(i-1)*sgroup; j<2+i*sgroup; j++ )
                                if( j != 2+i*sgroup-1 )
                                        printf $j"  "
                                else
                                        printf $j
                        print ""
                }
                
                if( (NF-1)%sgroup != 0 ){
                        printf $1"  "
                        for( j=NF-(NF-1)%sgroup+1; j<=NF; j++ )
                                if( j != NF )
                                        printf $j"  "
                                else
                                        printf $j
                        print ""
                }
        }else{
                print $0
        }
}' .values2$suff > .values3$suff
rm .values2$suff

# Para cada linea se obtienen los KEGG, pero solo los que estan coloreados
cat .values3$suff | while read line
do
	keggLine=`echo $line | sed 's/[[:blank:]]/+/g'`
	
	KEGG.sh -k $keggLine -s $specie -c -o $osuffix
done

# # keggLine=( `cat .values3$suff | sed -E 's/[[:blank:]]+/+/g'` )
# # 
# # for (( i=0; i<=$(( ${#keggLine[@]}/$nThreads-1 )); i++ ))
# # do
# # 	echo -n "Getting keggs ` seq -s " " $(( 1+$nThreads*$i )) $(( $nThreads+$nThreads*$i )) ` ... "
# # 	
# # 	for j in `seq 1 $nThreads`
# # 	do
# # 		ij=$(( $j+$nThreads*$i ))
# # 		KEGG.sh -k $keggLine -s $specie -c -o $osuffix &
# # 	done
# # 	
# # 	wait
# # 	
# # 	echo "OK"
# # done
# # 
# # ij=$(( $ij+1 ))
# # if (( $ij < ${#keggLine[@]} ))
# # then
# # 	for (( i=$ij; i<=${#keggLine[@]}; i++ ))
# # 	do
# # 		echo -n "Getting keggs $i ... "
# # 		KEGG.sh -k $keggLine -s $specie -c -o $osuffix
# # 		echo "OK"
# # 	done
# # fi

rm .values3$suff
