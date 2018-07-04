#!/bin/bash

SCRATCH="/tmp/$$"
OPREFIX="."

usage(){
cat > /dev/stdout << EOF
Usage:
	KEGG.sh [ -i geneID [-s specie_prefix] [-l] [-d] ] [ -k keggID [-s specie_prefix] [-c] ] -o oprefix
	
OPTIONS
	-i geneID
		Gene ID ( i.e. 9575 )
		
	-l
		Lista los KEGGs
		
	-d
		Lista los KEGGs con detalles
		
	-s specie_prefix
		Prefijo para la especie
		( default = hsa )
		
	-k keggID
		Retorna el archivo png del kegg asociado al id keggID
	
	-c
		Activa el flag: solo baja keggs coloreados
		
	-o oprefix
		Ruta para los archivos de salida
EOF
}

getKEGG(){
	local keggID=$1
	
	wget "http://www.kegg.jp/kegg-bin/show_pathway?$keggID" -o /dev/null -O $SCRATCH/.tmp.html
	href=`grep "/tmp/" $SCRATCH/.tmp.html | sed '{s/<img src="//g;s/" name="pathway.*//g}'`
	
	if [ -z "$href" -a $onlyColor = "F" ]
	then
		href=`grep "/kegg/pathway/" $SCRATCH/.tmp.html | sed '{s/<img src="//g;s/" usemap=.*//g}'`
	fi
	
	if [ -n "$href" ]
	then
		wget "http://www.kegg.jp$href" -o /dev/null
		
		# Para leer en formato humano con redundancias y separando por grupos
		# busca los genes dentro de las cajas del KEGG
		grep "shape=rect" $SCRATCH/.tmp.html \
			| gawk '
				BEGIN{
					FS="[=]"
					loc=0
				}
				{
					for( i=1; i<=NF; i++ ){
						if(loc==1){ print $i; loc=0 }
						if($i~/[[:blank:]]+title$/) loc=1
					}
				}' \
			| sed '{s/"//g; s/\/>//g}' \
			| gawk '($0~/^[[:digit:]]+/){gsub(/\(/,"",$0); gsub(/\)/,"\n",$0); print $0}' \
			| sed '{s/^[[:blank:]]*$/--------------------------------/g}' \
			| sed '{s/,/\n/g}' \
			| sed '{/^[[:blank:]]*$/d}' \
			| gawk '{
				if($1=="--------------------------------")
					print $1
				else{
					if($2~/^[[:blank:]]*$/)
						printf "%15s%5s%-15s\n","--"," ==> ",$1
					else
						printf "%15s%5s%-15s\n",$2," ==> ",$1
				}
			}' \
			> $SCRATCH/genes
		
		cp $SCRATCH/genes $OPREFIX/${keggID%%+*}.dat
		
		# Para continuar el procesamiento
		# Eliminar redundancias
		grep "shape=rect" $SCRATCH/.tmp.html \
			| gawk '
				BEGIN{
					FS="[=]"
					loc=0
				}
				{
					for( i=1; i<=NF; i++ ){
						if(loc==1){ print $i; loc=0 }
						if($i~/[[:blank:]]+title$/) loc=1
					}
				}' \
			| sed '{s/"//g; s/\/>//g}' \
			| gawk '($0~/^[[:digit:]]+/){gsub(/\(/,"",$0); gsub(/\)/,"\n",$0); print $0}' \
			| sed '{s/,/\n/g}' \
			| gawk '($0!~/^[[:blank:]]*$/){ map[$0]=1 }END{ for(key in map) print key }' | sort -k 2 \
			| gawk '{print $2" ==> "$1}' > $SCRATCH/genes
			 
		cat $SCRATCH/genes | gawk '{print $NF}' | while read line
		do
			wget "http://www.genome.jp/dbget-bin/www_bget?-f+-n+n+$specie:$line" -o /dev/null -O $SCRATCH/$line.fasta.tmp
			gawk 'BEGIN{loc=0}{if($0~/<\/pre>/)loc=0; if($0~/bget:db:genes/)loc=1; if(loc==1) print $0}' $SCRATCH/$line.fasta.tmp \
				| sed 's/<\!.*-->//g' > $SCRATCH/$line.fasta
		done
		
		cat $SCRATCH/*.fasta > $OPREFIX/${keggID%%+*}.fasta
	fi
	
	rm -rf $SCRATCH/.tmp.html
}

findKEGGs(){
	local geneID=$1
	
	wget "http://www.kegg.jp/kegg-bin/search_pathway_text?map=$specie&keyword=$geneID&mode=1&viewImage=true" -o /dev/null -O $SCRATCH/.tmp.html
	
	if [ ! -f $SCRATCH/.tmp.html ]
	then
		rm $SCRATCH/.tmp.html
		return
	fi
	
	gawk '
	function ltrim(s) { sub(/^[ \t]+/, "", s); return s }
	function rtrim(s) { sub(/[ \t]+$/, "", s); return s }
	function trim(s)  { return rtrim(ltrim(s)); }
	
	BEGIN{
		loc=0
	}
	{
		if( $1=="</tr>" ){
			loc=0
			
			if( KEGGID !~ /^[[:blank:]]*$/ ){
				data_url[KEGGID] = url
				data_name[KEGGID] = name
				data_descript[KEGGID] = descript
				data_legend[KEGGID] = legend
			}
		}
		
		if(loc==1){
			if( $2~/class=\"data1\"/ ){
				col += 1
				split($0,arr,"[<>]")
				if( col == 1 ) name=arr[3]
				if( col == 2 ) descript=arr[3]
				if( col == 4 ) legend=arr[3]
			}
		}
		
		if( $0~"http://www.genome.jp/dbget-bin/www_bget" ){
			split($0,arr,"[<>]")
			KEGGID = arr[3]
			
			split($0,arr," ")
			split(arr[3],arr,"\"")
			url = arr[2]
			
			loc=1
			col=0
		}
	}
	END{
		if( "'$listKEGG'" == "T" ){
			for( kegg in data_url ){
				print kegg
			}
		}else if( "'$listDetails'" == "T" ){
			for( kegg in data_url ){
				print kegg
				print "\t        url:", data_url[kegg]
				print "\t       name:", data_name[kegg]
				print "\tdescription:", data_descript[kegg]
				print "\t     legend:", data_legend[kegg]
			}
		}
	}
	' $SCRATCH/.tmp.html > $SCRATCH/.output
	
	if [ -z "`cat $SCRATCH/.output | gawk '{print $1}'`" ]
	then
		rm $SCRATCH/.tmp.html $SCRATCH/.output
		return
	fi
	
	cat $SCRATCH/.output
	
	rm -rf $SCRATCH/.tmp.html $SCRATCH/.output
}

main(){
	mkdir $SCRATCH
	
	listKEGG="F"
	listDetails="F"
	getKEGGID="0"
	specie="hsa"
	onlyColor="F"
	
	in="F"
	while getopts "i:ldk:s:co:" OPTNAME
	do
		case $OPTNAME in
			i)
				geneID=$OPTARG
				;;
			l)
				listKEGG="T"
				;;
			d)
				listDetails="T"
				;;
			k)
				keggID=$OPTARG
				;;
			s)
				specie=$OPTARG
				;;
			c)
				onlyColor="T"
				;;
			o)
				OPREFIX=$OPTARG
				;;
			*)
				usage
				exit 0
				;;
		esac
		in="T"
	done
	
	if [ $in = "F" ]
	then
		usage
		exit 0
	fi
	
	if [ "$listKEGG" = "T" -o "$listDetails" = "T" ]
	then
		if [ -n "$geneID" ]
		then
			findKEGGs $geneID
		else
			usage
			rm -rf $SCRATCH
			exit 0
		fi
		
	elif [ "$keggID" != "0" ]
	then
		getKEGG $keggID
	else
		usage
		rm -rf $SCRATCH
		exit 0
	fi
	
	rm -rf $SCRATCH
}

main $*
