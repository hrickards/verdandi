#!/bin/sh
rm -rf public

mkdir public

cp -rf app/html/* public/
cp -rf app/templates public/templates
cp -rf app/js public/js

compass compile --quiet
cp -rf .stylesheets-cache public/css
