#!/bin/bash
source insertToTemplate.sh

echo "Content-type: text/html"
echo ""
templateTop contact.html
templateContent contact.html
templateBottom contact.html