#!/bin/bash

url="$1"

if [[ -f "mods.json" ]]; then
    check=$(cat mods.json | jq "select(.url==\"$url\")")
    if [[ -n "$check" ]]; then
        echo "mod already added"
        exit 1
    fi
fi
site=$(curl -s "$url")
version=$(echo "$site" | grep -oP '<div id="version".*?</div>' | perl -pe 's/.*: (.*?)<\/div>/\1/;' -e 's/\s/_/g;' -e 's/_*$//')
md5=$(echo "$site" | grep -P 'MD5' | perl -pe 's/.*value="(.*?)".*/\1/')
downloadurl=$(echo $url | perl -pe 's#downloads/info#downloads/download#')
name=$(echo $url | perl -pe 's#.*?-(.*?).html#\1#')
tmpfile=$(mktemp)
cp mods.json $tmpfile
echo "{ \"name\":\"$name\", \"version\": \"$version\" , \"download\": \"$downloadurl\" , \"url\" : \"$url\" , \"md5\": \"$md5\"}" | jq . >> $tmpfile
jq -s '. | sort_by(.name) | .[]' $tmpfile > mods.json
rm $tmpfile
echo "list of mods:"
cat mods.json | jq -r .name
