#!/usr/bin/env bash

declare -a nodeLabels=("master" "amf" "smf" "upf")
declare -a workerNodes=("0" "1" "2" "3")

arrayIndex=0
for nodeNum in "${workerNodes[@]}"
do	
	node=node$nodeNum
	echo ""
	echo "Labelling Node - $node"
	echo ""
    kubectl label --overwrite nodes $node.$nodePrefix kubernetes.io/ztx-nf-type=${nodeLabels[arrayIndex]}
	echo ""
	echo "Finished Labelling Node - $node"
    echo ""
    arrayIndex=$((arrayIndex + 1))
done