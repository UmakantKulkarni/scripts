#!/usr/bin/env bash

ping_targets=("169.48.129.229" "69.45.92.173" "52.116.74.247")
total_seconds=8
sleep_time=3
curr_time=0
hour_count=1
while [ $curr_time -le $total_seconds ]
do
    failed_hosts=""
    echo "Hour # $hour_count"
    for i in "${ping_targets[@]}"
    do
        echo ""
        echo "Pinging server - $i"
        ping -c 2 $i
        if [ $? -ne 0 ]; then
            failed_hosts="$i"
        fi
    done
    echo ""
    echo "failed_hosts - $failed_hosts"
    echo "Ping failed to: $failed_hosts" | mail -s "Ping test results for hour # $hour_count" ukulkarn@purdue.edu
    curr_time=$(( $curr_time + $sleep_time ))
    hour_count=$(( $hour_count + 1 ))
    echo "Sleeping for $sleep_time seconds"
    sleep $sleep_time
    echo ""
done
