#!/bin/bash
while true
do
        date >> top_data.txt
        top -b -n 1 >> top_data.txt
        echo " " >> top_data.txt
        sleep 0.2
done