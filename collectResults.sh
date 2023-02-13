#!/usr/bin/env bash

cd /opt/ && mkdir -p Results

for nodexp in /opt/Node_Ops/* ; 
do
    f1=`basename $nodexp`
    for exp in $nodexp/* ; 
    do
        f2=`basename $exp`
        for subexp in $exp/* ; 
        do
            f3=`basename $subexp`
            mkdir -p /opt/Results/$f2/$f3/
            cmd="scp -o StrictHostKeyChecking=no $subexp/* /opt/Results/$f2/$f3/"
            eval "$cmd"
        done
    done
done

for uexp in /opt/Ue_Ops/* ;
do
    f1=`basename $uexp`
    for exp in $uexp/* ;
    do
        f2=`basename $exp`
        for subexp in $exp/* ;
        do
            f3=`basename $subexp`
            mkdir -p /opt/Results/$f2/$f3/
            for filename in $subexp/* ; 
            do
                f4=`basename $filename`
                cmd="scp -o StrictHostKeyChecking=no $subexp/$f4 /opt/Results/$f2/$f3/${f4}_${f1}"
                eval "$cmd"
            done
        done
    done
done
