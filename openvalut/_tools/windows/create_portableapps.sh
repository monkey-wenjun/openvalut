#!/bin/bash

set -xeu

# Create a portableapps.com release

#prevdir="${pwd}"

relative_dir="${0%/*}"

pushd "${relative_dir}"
dir="$(pwd)"
popd

basedir="${dir}/../../"

url="https://openvalut-data.codeux.design/data/artifacts"
template_url="https://data.example.com/data/PortableApps.com_Application_Template_3.5.2.zip"

tmpdir=$(mktemp -d)
cd "${tmpdir}"

fullversion="$(curl "${url}/openvalut-portable-latest.zip.txt")"
version="$(echo "$fullversion" | cut -d'_' -f1)"
buildnumber="$(echo "$fullversion" | cut -d'_' -f2)"

echo "Building for ${fullversion} (version: ${version} buildnumber: ${buildnumber}"


curl -o template.zip "${template_url}"
curl -o openvalut-portable.zip "${url}/openvalut-portable-${fullversion}.zip"

unzip template.zip

mv AppNamePortable openvalutPortable

cd openvalutPortable
unzip ../openvalut-portable.zip

rm ../openvalut-portable.zip
mv AppNamePortable.exe openvalutPortable.exe
rm -r App/AppName
rm -r App/DefaultData
cp -r "${dir}/portableapps"/* .

sed -i '' "s/PackageVersion=.*/PackageVersion=${version}.${buildnumber}/" App/AppInfo/appinfo.ini
sed -i '' "s/DisplayVersion=.*/DisplayVersion=${version}/" App/AppInfo/appinfo.ini

cd ..

zipfile="openvalutPortable-${fullversion}.zip"
zip -r "${zipfile}" openvalutPortable

mkdir -p "${basedir}/build/windows"
cp "${zipfile}" "${basedir}/build/windows"

rm -rf "${tmpdir}"
