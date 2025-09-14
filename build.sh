#!/bin/bash

gamename=$(basename $(pwd))

echo "assembling..."
ca65 main.s -o bin/main.o
if [ $? != 0 ]; then return; fi

echo "linking..."
ld65 -C ../lorom.cfg -o "bin/$gamename.sfc" bin/main.o
