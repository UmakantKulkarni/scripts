#!/usr/bin/env bash

cd /proj/sfcs-PG0/opt/ && mkdir -p Ue_Ops

ocmd="scp -o StrictHostKeyChecking=no -r /opt/Experiments/* root@node0:/proj/sfcs-PG0/opt/Ue_Ops"
for i in "$@"
do	
	node=node$i
	echo ""
	echo "Starting SCP From Node - $node"
	echo ""
    cd /proj/sfcs-PG0/opt/Ue_Ops && mkdir -p $node
    wcmd="$ocmd/$node/ && exit"
    ssh -o StrictHostKeyChecking=no root@$node "$wcmd"
	echo ""
	echo "Finished SCP From Node - $node"
        echo ""
        nodeNum=$((nodeNum + 1))
done