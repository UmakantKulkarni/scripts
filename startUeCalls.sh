#!/usr/bin/env bash

numSession="$1"
edir="$2"

cd $edir && nr-ue -c /opt/UERANSIM/config/oai-ue.yaml -n $numSession > $edir/uesim.logs 2>&1 &