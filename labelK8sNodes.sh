#!/usr/bin/env bash

nodePrefix="$1"
declare -a nodeLabels=("master" "amf" "smf" "upf")
declare -a workerNodes=("0" "1" "2" "3")

arrayIndex=0
for nodeNum in "${workerNodes[@]}"
do	
	node=node$nodeNum
	nodename=$node.$nodePrefix
	if [ "$nodePrefix" == "kind" ]; then
		if [ "$nodeNum" == "0" ]; then
			nodename="kind-control-plane"
		elif [ "$nodeNum" == "1" ]; then
			nodename="kind-worker"
		elif [ "$nodeNum" == "2" ]; then
			nodename="kind-worker2"
		elif [ "$nodeNum" == "3" ]; then
			nodename="kind-worker3"
		fi
	fi
	echo ""
	echo "Labelling Node - $node"
	echo ""
    kubectl label --overwrite nodes $nodename pcs-nf-type=${nodeLabels[arrayIndex]}
	echo ""
	echo "Finished Labelling Node - $node"
    echo ""
    arrayIndex=$((arrayIndex + 1))
done