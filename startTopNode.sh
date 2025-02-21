#!/usr/bin/env bash

if [[ $# -le 2 ]] ; then
	echo "Expected at least 2 CLI arguments - Sub-directory & experiment directory to save output and Node Numbers"
    exit 1
fi

experimentDir="$1"
pcsDir="$2"

ocmd="cd /opt/ && mkdir -p Experiments && cd Experiments && mkdir -p $experimentDir && cd $experimentDir && mkdir -p $pcsDir && cd $pcsDir && rm -f top_data_*.txt && (bash /opt/scripts/topFile.sh > /dev/null 2>&1 &)"
ktcmd="cd /opt/Experiments/$experimentDir/$pcsDir && rm -f kt_data.txt && (bash /opt/scripts/ktopFile.sh > /dev/null 2>&1 &)"
mcmd="$ktcmd && exit"
wcmd="$ocmd && exit"

dscmd="cd /opt/Experiments/$experimentDir/$pcsDir && rm -f docker_data_*.txt && (bash /opt/scripts/dockerStats.sh > /dev/null 2>&1 &)"
psscmd="cd /opt/Experiments/$experimentDir/$pcsDir && rm -f open5gs*_ss.txt && (bash /opt/scripts/ssPodOp.sh > /dev/null 2>&1 &)"
dswcmd="$dscmd && exit"

for i in "${@:3}"
do
    node=node$i
	echo ""
	echo "Starting top-start script on node - $node"
	echo ""
    if [[ $i -eq 0 ]] ; then
        #eval "$dscmd"
        eval "$psscmd"
        ssh -o StrictHostKeyChecking=no root@$node "$wcmd"
        ssh -o StrictHostKeyChecking=no root@$node "$mcmd"
    else
        #ssh -o StrictHostKeyChecking=no root@$node "$dswcmd"
        ssh -o StrictHostKeyChecking=no root@$node "$wcmd"
    fi
	echo ""
	echo "Started top-start script on node - $node"
    echo ""
done