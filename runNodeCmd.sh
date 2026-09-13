#!/usr/bin/env bash

cmd="$1"
for i in "${@:2}"
do
    node=node$i
    echo ""
    echo "Executing command on Node - $node"
    echo ""
    ssh -o StrictHostKeyChecking=no root@$node "$cmd"
    echo ""
    echo "Finished executing command on Node - $node"
        echo ""
        nodeNum=$((nodeNum + 1))
done