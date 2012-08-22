#!/bin/sh
rm -rf public

mkdir public

cp -rf html/* public/
cp -rf templates public/templates
cp -rf js public/js
