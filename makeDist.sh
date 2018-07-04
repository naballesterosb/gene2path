#!/bin/bash

mkdir gene2path
cp gene2path.conf gene2path/
cp README gene2path/
cp -r bin gene2path/
cp -r data gene2path/
cp -r test gene2path/

zip -r gene2path-`date +%Y%m%d`.zip gene2path
rm -rf gene2path
