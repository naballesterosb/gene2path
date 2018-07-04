#!/bin/bash

# Modo de uso ./insertToTemplate code/install.html > install.html
TEMPLATE_PATH=$PWD/template

templateContent()
{
	gawk '
	BEGIN{
		body = false ;
	}
	
	{
		if( $0~/<\/body>/ ){
			body = false ;
		}               
		
		if( body == 1 ){
			print $0 ;
		}
			
		if( $0~/<body>/ ){
			body = 1 ;
		}
			
	}' $1
}

templateTop()
{
	# Selecciona el titulo correcto para la página
	TITLE=`grep "<title>" $1`
	gawk -v title="$TITLE" '{ if($0~/<title>/){ print title }else{ print $0 }}' $TEMPLATE_PATH/top.html > /tmp/top.html
	
# 	cat $TEMPLATE_PATH/top.html
	cat /tmp/top.html
	rm /tmp/top.html
}

templateBottom()
{
	cat $TEMPLATE_PATH/bottom.html
}
