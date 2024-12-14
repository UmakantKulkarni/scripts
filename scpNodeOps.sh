#!/usr/bin/env bash

cd /opt/ && mkdir -p Node_Ops

ocmd="scp -o StrictHostKeyChecking=no -r /opt/Experiments/* root@node0:/opt/Node_Ops"
for i in "$@"
do	
	node=node$i
	echo ""
	echo "Starting SCP From Node - $node"
	echo ""
    cd /opt/Node_Ops && mkdir -p $node
    wcmd="$ocmd/$node/ && exit"
    ssh -o StrictHostKeyChecking=no root@$node "$wcmd"
	echo ""
	echo "Finished SCP From Node - $node"
        echo ""
        nodeNum=$((nodeNum + 1))
done

for uexp in /opt/Node_Ops/* ;
do
    f1=`basename $uexp`
    for exp in $uexp/* ;
    do
        f2=`basename $exp`
        for subexp in $exp/* ;
        do
            f3=`basename $subexp`
            for filename in $subexp/* ; 
            do
                f4=`basename $filename`
                cmd="scp -o StrictHostKeyChecking=no $subexp/$f4 /opt/Experiments/$f2/$f3/${f4}_${f1}"
                eval "$cmd"
            done
        done
    done
done