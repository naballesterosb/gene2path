#!/bin/bash

showSpecies="F"
specie=""

SCRATCH="/tmp"

usage(){
cat << EOF
USAGE:
	homology.sh [ -i gbID ] [ -l | -s specieName ]
	
OPTIONS
	-i gbID
		Gene bank ID
	-l
		List the species with homology
	-s
		Search only for specieName
EOF
}

getHomology(){
	local gbID=$1
	
	wget http://www.ncbi.nlm.nih.gov/gene/?term=$gbID -o /dev/null -O $SCRATCH/.tmp.html-homology$$
	href=`grep -A3 "Additional Links" $SCRATCH/.tmp.html-homology$$ | grep "href" | gawk 'BEGIN{FS="[<>[:blank:]]+"}{print $5}' | sed '{s/href="//g;s/"//g}'`
	rm -rf $SCRATCH/.tmp.html-homology$$
	
	if [ -n "$href" ]
	then
		wget $href -o /dev/null -O $SCRATCH/.tmp.html-homology$$
	else
		wget "http://www.ncbi.nlm.nih.gov/unigene?term=$gbID" -o /dev/null -O $SCRATCH/.tmp-homology$$.html > /dev/null
		href=`grep "/UniGene/clust.cgi" $SCRATCH/.tmp-homology$$.html | sed 's/ /\n/g' | gawk '($1~/href=.*UniGene/){print $1}' | sed '{s/href=//g;s/"//g}'`
		rm -rf $SCRATCH/.tmp-homology$$
		
		if [ -n "$href" ]
		then
			wget "http://www.ncbi.nlm.nih.gov/$href" -o /dev/null -O $SCRATCH/.tmp.html-homology$$
		else
			echo "## ERROR ## Gene not found"
			return
		fi
	fi
	
	if [ ! -f $SCRATCH/.tmp.html-homology$$ ]
	then
		rm $SCRATCH/.tmp.html-homology$$
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
		if( $0~"<META name=\"description\"" ){
			split($0,arr,"[")
			split(arr[2],arr2,"]")
			split(arr2[1],arr3,"[[:blank:]]" )
			unigenTrout = arr3[2]
			split(arr2[1],arr4,"[.]")
			omy = arr4[2]
		}

		if( $1=="</tr>" ){
			loc=0
			
			if( specie !~ /^[[:blank:]]*$/ ){
				data_species[specie] = 1
				data_protID[specie] = protID
				data_protName[specie] = protName
				data_ld[specie] = ld
				data_len[specie] = len
				data_genURL[specie] = geneURL
			}
		}
		
		if(loc==1){
			if( $0~/Gene summary/ ){
				split($2,arr,"\"")
				geneURL=arr[2]
			}
			
			if( $2~/class=\"TEXT\"/ ){
				col += 1
				split($0,arr,"[<>]")
				if( col == 1 ) protName=arr[3]
				if( col == 2 ) specie=arr[5]
				if( col == 3 ) ld=arr[3]
				if( col == 4 ) len=arr[3]
			}
		}
		
		if( $0~"#Menu_prot" ){
			split($9,arr,"[<>]")
			protID = arr[2]
			loc=1
			col=0
		}
	}
	END{
		if( "'$showSpecies'" == "T" ){
			for( specie in data_species ){
				sub(" ","",specie)
				print specie
			}
		}else{
			for( specie in data_species ){
				rawSpecie=specie
				sub(" ","",specie)
				
				if( specie == "'"$specie"'" ){
					protNameEff=trim(data_protName[rawSpecie])
					gsub(/[[:blank:]]+/,"_",protNameEff)
					
					print "\t   UniGeneTrout:", unigenTrout
					print "\t   Omy:", omy
					
					print specie
					print "\t     gbID:", "'$gbID'"
					print "\t   protID:", data_protID[rawSpecie]
					print "\t protName:", protNameEff
					print "\t       ld:", data_ld[rawSpecie]
					print "\t      len:", data_len[rawSpecie]
					print "\t  geneURL:", data_genURL[rawSpecie]
				}
			}
		}
	}
	' $SCRATCH/.tmp.html-homology$$ > $SCRATCH/.output-homology$$ 2> /dev/null
		
	if [ -z "`cat $SCRATCH/.output-homology$$ | gawk '{print $1}'`" ]
	then
		rm $SCRATCH/.tmp.html-homology$$ $SCRATCH/.output-homology$$
		return
	fi
	
	if [ "$showSpecies" = "F" -a -n "$specie" ]
	then
		cat $SCRATCH/.output-homology$$
		
		protID=`cat $SCRATCH/.output-homology$$ | grep "protID" | gawk '{print $2}'`
		geneURL=`cat $SCRATCH/.output-homology$$ | grep "geneURL" | gawk '{print $2}'`
		wget "http://www.ncbi.nlm.nih.gov/$geneURL" -o /dev/null -O $SCRATCH/.tmp.html-homology$$
		
		geneID=`grep "Gene ID:" $SCRATCH/.tmp.html-homology$$ | gawk 'BEGIN{FS="[<>]"}{print $3}' | gawk '{print $3}' | sed 's/,//g'`
		echo -e "\t   geneID: $geneID"
		
		geneSym=`grep -A1 "Gene symbol" $SCRATCH/.tmp.html-homology$$ | tail -n1 | gawk 'BEGIN{FS="[<>]"}{print $3}'`
		echo -e "\t  geneSym: $geneSym"
	else
		cat $SCRATCH/.output-homology$$
	fi
	
	rm $SCRATCH/.tmp.html-homology$$ $SCRATCH/.output-homology$$
}

main(){
	in=0
	while getopts "i:ls:" OPTNAME
	do
		in=1
		case $OPTNAME in
			i)
				gbID=$OPTARG
				;;
			l)
				showSpecies="T"
				;;
			s)
				specie=$OPTARG
				;;
			*)
				usage
				exit 0
				;;
		esac
	done
	
	if [ "$in" -ne 1 ]
	then
		usage
		exit 0
	fi
	
	getHomology $gbID
}

main $*
