#!/bin/bash
source insertToTemplate.sh

echo "Content-type: text/html"
echo ""
templateTop programs.html
templateContent programs.html
templateBottom programs.html