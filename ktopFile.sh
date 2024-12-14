#!/usr/bin/env bash

while true
do
        date +"%F--%T.%N" >> kt_data.txt
        kubectl top pods -A --containers >> kt_data.txt
        echo " " >> kt_data.txt
        sleep 1
done