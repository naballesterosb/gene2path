#!/bin/bash 

# AF123654 AC091799 AC145615
# trucha AB176854.1 5823059 8489852

for geneID in $*
do
	echo $geneID \
		| gbseqget \
		| sgrep -o "%r\n" '"<GBSeqid>" __ "</GBSeqid>"' \
		| sed 's/|/ /g' \
		| gawk '{printf $1":"$2"  "}END{print ""}'
done
