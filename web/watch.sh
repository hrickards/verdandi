#!/bin/sh
while inotifywait -r `pwd` -e modify -e move -e create -e delete -q -q; do
  ./build
done
