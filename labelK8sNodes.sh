#!/usr/bin/env bash

declare -a nodeLabels=("master" "amf" "smf" "upf" "nf")
declare -a nodes=("kind-control-plane" "kind-worker" "kind-worker2" "kind-worker3" "kind-worker4")

arrayIndex=0
for node in "${nodes[@]}"
do	
	echo ""
	echo "Labelling Node - $node"
	echo ""
    kubectl label --overwrite nodes $node kubernetes.io/pcs-nf-type=${nodeLabels[arrayIndex]}
	echo ""
	echo "Finished Labelling Node - $node"
    echo ""
    arrayIndex=$((arrayIndex + 1))
done