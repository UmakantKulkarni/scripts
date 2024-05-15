#!/usr/bin/env bash

if [[ $# -ne 1 ]] ; then
    echo "Expected at least 1 CLI argument - Node number"
    exit 1
fi

ocmd="pkill -f topFile.sh"
ktcmd="pkill -f ktopFile.sh"
dscmd="pkill -f dockerStats.sh"
psscmd="pkill -f ssPodOp.sh"

mcmd="$ktcmd && exit"
wcmd="$ocmd && exit"
dswcmd="$dscmd && exit"

for i in "${@:1}"
do
	node=node$i
	echo ""
	echo "Stopping top-start script on node - $node"
	echo ""
    if [[ $i -eq 0 ]] ; then
        #eval "$ocmd"
        #eval "$ktcmd"
        #eval "$dscmd"
        #eval "$psscmd"
        ssh -o StrictHostKeyChecking=no root@$node "$wcmd"
        ssh -o StrictHostKeyChecking=no root@$node "$mcmd"
    else
        ssh -o StrictHostKeyChecking=no root@$node "$wcmd"
        #ssh -o StrictHostKeyChecking=no root@$node "$dswcmd"
    fi
	echo ""
	echo "Stopped top-start script on node - $node"
    echo ""
done