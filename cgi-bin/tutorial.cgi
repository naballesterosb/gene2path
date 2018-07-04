#!/bin/bash
source insertToTemplate.sh

echo "Content-type: text/html"
echo ""
templateTop tutorial.html
templateContent tutorial.html
templateBottom tutorial.html