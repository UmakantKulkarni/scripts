#!/usr/bin/env bash

if [ "$#" -lt 1 ]; then
    echo 'Expected 1 CLI arguments - Kubernetes join command'
    exit 1
fi

kjoincmd="$1"
eval $kjoincmd
