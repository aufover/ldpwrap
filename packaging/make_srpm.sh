#!/bin/bash

rm -rf ./tmp
mkdir -p ./tmp
cp ../src/* ./tmp
cd tmp
tar -cf ./ldpwrap.tar.gz ./*
cd ..
rpmbuild -bs ./ldpwrap.spec --define "_sourcedir $PWD/tmp" --define "_srcrpmdir $PWD"
rm -rf ./tmp
