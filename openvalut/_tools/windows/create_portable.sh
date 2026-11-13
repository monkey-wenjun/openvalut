#!/bin/bash

set -xeu

# input arguments
version=${version:?}
buildnumber=${buildnumber:?}

reldir="build/_openvalut/windows/release/openvalut"
portdir="build/_openvalut/windows/release/portable"
#portableappsdir="build/_openvalut/windows/release/portableapps"
zipfilename="openvalut-portable-${version}_${buildnumber}.zip"
zipfile="build/_openvalut/windows/release/${zipfilename}"

mkdir -p "${portdir}/App"
cp -r "${reldir}" "${portdir}/App/openvalut"

echo "App\\openvalut\\openvalut.exe" > "${portdir}/openvalut.bat"
echo "${version}_${buildnumber}" > "${portdir}/version.txt"

pushd ${portdir}
#portdirabs="$(pwd)"
7z a "../${zipfilename}" -r ./*
popd

outputfilename="${zipfilename}"
outputpath="${zipfile}"
#echo "${version}+${buildnumber}" > build/${flavor}/release/version.txt
#echo "${version}+${buildnumber}" > build/${flavor}/release/bundle/version.txt
#tar czvf ${outputpath} --transform "s/^build.*bundle/openvalut/" build/${flavor}/release/bundle
echo "::set-output name=appversion::${version}"
echo "::set-output name=outputfilename::${outputfilename}"
echo "::set-output name=outputpath::${outputpath}"

## now create portableapps.com distribution
#
#zipfilename="openvalutPortableApps-${version}_${buildnumber}.zip"
#
#pushd ${portableappsdir}
#wget -O apptemplate.zip https://data.example.com/data/PortableApps.com_Application_Template_3.5.2.zip
#7z x apptemplate.zip
#mv AppNamePortable openvalutPortable
#cp -r "${portdirabs}"/* openvalutPortable/
#7z a "../${zipfilename}"