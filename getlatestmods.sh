#!/bin/bash


downloadmod()
{
    filename=$1
    url=$2
    md5=$3
    ls archive/$filename.* &>/dev/null
    if [[ $? -eq 0 ]]; then
        mv archive/$filename.* modfiles/.
        return
    fi
    echo "downloading $filename"
    site=$(curl -s $url)
    downloadurl=$(echo $site | grep -oP '<div class="manuallink">.*?</a>' | perl -pe 's/.*?<a href="(.*?)".*/\1/')
    ending=$(echo $downloadurl | perl -pe 's/.*\.(.*?)\?.*/\1/')
    mkdir -p modfiles
    curl  -s "$downloadurl" > modfiles/${filename}.$ending
    md5d=($(md5sum modfiles/${filename}.$ending))
    if [[ "$md5" != "$md5d" ]]; then
        echo Checksum error for $filename.$ending >&2
        rm -v modfiles/${filename}.$ending
    fi
}


downloadallmods()
{
    mkdir -p archive
    mkdir -p modfiles
    mv modfiles/* archive
    while read i; do
        name=$(echo $i | jq -r '.name')
        version=$(echo $i | jq -r '.version')
        url=$(echo $i | jq -r '.download')
        md5=$(echo $i | jq -r '.md5')
        filename="${name}_${version}"
        downloadmod $filename $url $md5
    done < <(jq -c . mods.json)
}

checkversions()
{
    while read i; do
        oldversion=$(echo $i | jq -r '.version')
        url=$(echo $i | jq -r '.url')
        site=$(curl -s "$url")
        version=$(echo "$site" | grep -oP '<div id="version".*?</div>' | perl -pe 's/.*: (.*?)<\/div>/\1/;' -e 's/\s/_/g;' -e 's/_*$//')
        md5=$(echo "$site" | grep -P 'MD5' | perl -pe 's/.*value="(.*?)".*/\1/')
        downloadurl=$(echo $url | perl -pe 's#downloads/info#downloads/download#')
        name=$(echo $url | perl -pe 's#.*?-(.*?).html#\1#')

        if [[ "$version" !=  "$oldversion" ]]; then
            echo found update for $name old:$oldversion new:$version
            tmpfile=$(mktemp)
            jq "select(.url!=\"$url\")" mods.json > $tmpfile
            echo "{ \"name\":\"$name\", \"version\": \"$version\" , \"download\": \"$downloadurl\" , \"url\" : \"$url\" , \"md5\": \"$md5\"}" | jq . >> $tmpfile
            jq -s '. | sort_by(.name) | .[]' $tmpfile > mods.json
            rm $tmpfile
        fi

    done < <(jq -c . mods.json)
}
checkversions
downloadallmods
