#!/bin/bash
scriptfolder=$(dirname $(readlink -f $0))
if [[ -d AddOns ]]; then
    cd AddOns
    rm -rf *
    readlink -f $scriptfolder/modfiles/* | xargs -n1 unzip
    if [[ -d TamrielTradeCentre ]]; then
        cd TamrielTradeCentre
        curl -L https://eu.tamrieltradecentre.com/download/PriceTable > PriceTable.zip
        unzip PriceTable.zip
    fi

fi
