#!/bin/bash
source insertToTemplate.sh

echo "Content-type: text/html"
echo ""
templateTop index.html
templateContent index.html
templateBottom index.html
