#!/usr/bin/env bash

commonTZ="MDT"
exp=/proj/sfcs-PG0/opt/Results
#exp="/Users/umakantkulkarni/PurdueOneDrive/OneDrive\ -\ purdue.edu/Research/Req-Rsp/Experiments/Run6/Results"
exp=/home/ukulkarn/Run6

csv_op_file=$exp/ueTransTimes.csv
echo "imsi,epoch_regcomp_ts1,epoch_create_start,epoch_create_end,epoch_pfcpcreate_end,epoch_n1n2_end,epoch_pfcpupdate_end,epoch_update_end,epoch_regcomp_ts2,epoch_create_start2,epoch_create_end2,epoch_pfcpcreate_end2,epoch_n1n2_end2,epoch_pfcpupdate_end2,epoch_update_end2,epoch_regcomp_ts3,epoch_create_start3,epoch_create_end3,epoch_pfcpcreate_end3,epoch_n1n2_end3,epoch_pfcpupdate_end3,epoch_update_end3" >> $csv_op_file

f1="Single-Read-Enabled"
f2="Fully-Transactional-Stateless"
f3="All-NFs-Share-Udsf"
j1=7
j2=9
j3=7
echo "Working on $exp/$f1"
echo "Working on $exp/$f2"
echo "Working on $exp/$f3"
echo " "
subexp=100

amflogFile1=$exp/$f1-$j1/$subexp/open5gs-amf-deployment-*_logs.txt
amflogFile2=$exp/$f2-$j2/$subexp/open5gs-amf-deployment-*_logs.txt
amflogFile3=$exp/$f3-$j3/$subexp/open5gs-amf-deployment-*_logs.txt
smflogFile1=$exp/$f1-$j1/$subexp/open5gs-smf-deployment-*_logs.txt
smflogFile2=$exp/$f2-$j2/$subexp/open5gs-smf-deployment-*_logs.txt
smflogFile3=$exp/$f3-$j3/$subexp/open5gs-smf-deployment-*_logs.txt
for imsi in $(seq -f "%04g" 1 50)
do
    echo "IMSI is - $imsi"

    echo "Transaction is $f1"

    grep_op1=$(cat $amflogFile1 | grep "\[suci-0-208-93-0000-0-0-000000$imsi\] Unknown UE by SUCI" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_regcomp_ts1=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_regcomp_ts1 is - $epoch_regcomp_ts1"

    grep_op1=$(cat $amflogFile1 | grep "UE SUPI\[imsi-20893000000$imsi\] DNN\[internet\] S_NSSAI" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_create_start=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_create_start is - $epoch_create_start"

    grep_op1=$(cat $amflogFile1 | grep "PCS Successfully completed Create transaction with shared UDSF for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_create_end=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_create_end is - $epoch_create_end"

    grep_op1=$(cat $smflogFile1 | grep "PCS Successfully uploaded N4 Create data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_pfcpcreate_end=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_pfcpcreate_end is - $epoch_pfcpcreate_end"

    grep_op1=$(cat $smflogFile1 | grep "PCS Successfully uploading n1-n2 transfer data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_n1n2_end=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_n1n2_end is - $epoch_n1n2_end"

    grep_op1=$(cat $smflogFile1 | grep "PCS Successfully uploaded Update-SM-Context & N4 modify data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_pfcpupdate_end=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_pfcpupdate_end is - $epoch_pfcpupdate_end"

    grep_op1=$(cat $amflogFile1 | grep "PCS Successfully completed Update-SM-Context transaction with shared UDSF for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_update_end=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_update_end is - $epoch_update_end"

    if (( 0 )) ; then

        grep_op1=$(cat $amflogFile1 | grep "\[suci-0-208-93-0000-0-0-000000$imsi\] Unknown UE by SUCI" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
        opfmt=$(echo $utcTs | cut -c 1-)
        epoch_start_ts1=$(date -d "$utcTs" +"%s.%3N")
        echo "epoch_start_ts1 is - $epoch_start_ts1"

        grep_op1=$(cat $amflogFile1 | grep "UE SUPI\[imsi-20893000000$imsi\] DNN[internet] S_NSSAI" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
        opfmt=$(echo $utcTs | cut -c 1-)
        epoch_create_start=$(date -d "$utcTs" +"%s.%3N")
        echo "epoch_create_start is - $epoch_create_start"

        grep_op1=$(cat $smflogFile1 | grep "UE SUPI\[imsi-20893000000$imsi\] DNN[internet] IPv4" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
        opfmt=$(echo $utcTs | cut -c 1-)
        epoch_pfcpcreate_start=$(date -d "$utcTs" +"%s.%3N")
        echo "epoch_pfcpcreate_start is - $epoch_pfcpcreate_start"

        grep_op1=$(cat $amflogFile1 | grep "\[imsi-20893000000$imsi\] Registration complete" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
        opfmt=$(echo $utcTs | cut -c 1-)
        epoch_regcomp_ts1=$(date -d "$utcTs" +"%s.%3N")
        echo "epoch_regcomp_ts1 is - $epoch_regcomp_ts1"

        grep_op1=$(cat $amflogFile1 | grep "PCS Successfully completed n1-n2 transaction with shared UDSF for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
        opfmt=$(echo $utcTs | cut -c 1-)
        epoch_n1n2_ts1=$(date -d "$utcTs" +"%s.%3N")
        echo "epoch_n1n2_ts1 is - $epoch_n1n2_ts1"

        time_diff=$(bc <<< "$epoch_regcomp_ts - $epoch_start_ts")
        echo "For UE with imsi IMSI-20893000000$imsi, Registration time is - $time_diff"
        time_diff=$(bc <<< "$epoch_create_ts - $epoch_regcomp_ts")
        echo "For UE with imsi IMSI-20893000000$imsi, Create time is - $time_diff"
        time_diff=$(bc <<< "$epoch_n1n2_ts - $epoch_create_ts")
        echo "For UE with imsi IMSI-20893000000$imsi, N1-N2 time is - $time_diff"
        time_diff=$(bc <<< "$epoch_update_ts - $epoch_n1n2_ts")
        echo "For UE with imsi IMSI-20893000000$imsi, Update time is - $time_diff"
    

        grep_op1=$(cat $amflogFile1 | grep "PCS Successfully completed Update-SM-Context transaction with shared UDSF for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
        opfmt=$(echo $utcTs | cut -c 1-)
        epoch_update_ts1=$(date -d "$utcTs" +"%s.%3N")
        echo "epoch_update_ts1 is - $epoch_update_ts1"
        
        time_diff1=$(bc <<< "$epoch_update_ts1 - $epoch_start_ts1")
        echo "For UE with imsi IMSI-20893000000$imsi, Total SRE Procedure time is - $time_diff1"

        grep_op1=$(cat $amflogFile2 | grep "\[suci-0-208-93-0000-0-0-000000$imsi\] Unknown UE by SUCI" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
        opfmt=$(echo $utcTs | cut -c 1-)
        epoch_start_ts2=$(date -d "$utcTs" +"%s.%3N")
        echo "epoch_start_ts2 is - $epoch_start_ts2"

        grep_op1=$(cat $amflogFile2 | grep "PCS Successfully uploaded Update-SM-Context data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
        opfmt=$(echo $utcTs | cut -c 1-)
        epoch_update_ts2=$(date -d "$utcTs" +"%s.%3N")
        echo "epoch_update_ts2 is - $epoch_update_ts2"
        
        time_diff2=$(bc <<< "$epoch_update_ts2 - $epoch_start_ts2")
        echo "For UE with imsi IMSI-20893000000$imsi, Total FTS Procedure time is - $time_diff2"

    fi

    echo "Transaction is $f2"

    grep_op1=$(cat $amflogFile2 | grep "\[suci-0-208-93-0000-0-0-000000$imsi\] Unknown UE by SUCI" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_regcomp_ts2=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_regcomp_ts2 is - $epoch_regcomp_ts2"

    grep_op1=$(cat $amflogFile2 | grep "UE SUPI\[imsi-20893000000$imsi\] DNN\[internet\] S_NSSAI" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_create_start2=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_create_start2 is - $epoch_create_start2"

    grep_op1=$(cat $amflogFile2 | grep "PCS Successfully inserted Create-SM-Context data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_create_end2=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_create_end2 is - $epoch_create_end2"

    grep_op1=$(cat $smflogFile2 | grep "PCS Successfully uploaded N4 Create data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_pfcpcreate_end2=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_pfcpcreate_end2 is - $epoch_pfcpcreate_end2"

    grep_op1=$(cat $smflogFile2 | grep "PCS Successfully uploading n1-n2 transfer data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_n1n2_end2=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_n1n2_end2 is - $epoch_n1n2_end2"

    grep_op1=$(cat $smflogFile2 | grep "PCS Successfully uploaded Update-SM-Context & N4 modify data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_pfcpupdate_end2=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_pfcpupdate_end2 is - $epoch_pfcpupdate_end2"

    grep_op1=$(cat $amflogFile2 | grep "PCS Successfully uploaded Update-SM-Context data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_update_end2=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_update_end2 is - $epoch_update_end2"



    echo "Transaction is $f3"

    grep_op1=$(cat $amflogFile3 | grep "\[suci-0-208-93-0000-0-0-000000$imsi\] Unknown UE by SUCI" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_regcomp_ts3=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_regcomp_ts3 is - $epoch_regcomp_ts3"

    grep_op1=$(cat $amflogFile3 | grep "UE SUPI\[imsi-20893000000$imsi\] DNN\[internet\] S_NSSAI" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_create_start3=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_create_start3 is - $epoch_create_start3"

    grep_op1=$(cat $amflogFile3 | grep "PCS Successfully completed Create transaction with shared UDSF for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_create_end3=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_create_end3 is - $epoch_create_end3"

    grep_op1=$(cat $smflogFile3 | grep "PCS Successfully uploaded N4 Create data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_pfcpcreate_end3=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_pfcpcreate_end3 is - $epoch_pfcpcreate_end3"

    grep_op1=$(cat $smflogFile3 | grep "PCS Successfully uploading n1-n2 transfer data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_n1n2_end3=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_n1n2_end3 is - $epoch_n1n2_end3"

    grep_op1=$(cat $smflogFile3 | grep "PCS Successfully uploaded Update-SM-Context & N4 modify data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_pfcpupdate_end3=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_pfcpupdate_end3 is - $epoch_pfcpupdate_end3"

    grep_op1=$(cat $amflogFile3 | grep "PCS Successfully completed Update-SM-Context transaction with shared UDSF for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_update_end3=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_update_end3 is - $epoch_update_end3"

    #echo "20893000000$imsi, $time_diff1, $time_diff2" >> $csv_op_file

    echo "20893000000$imsi,$epoch_regcomp_ts1,$epoch_create_start,$epoch_create_end,$epoch_pfcpcreate_end,$epoch_n1n2_end,$epoch_pfcpupdate_end,$epoch_update_end,$epoch_regcomp_ts2,$epoch_create_start2,$epoch_create_end2,$epoch_pfcpcreate_end2,$epoch_n1n2_end2,$epoch_pfcpupdate_end2,$epoch_update_end2,$epoch_regcomp_ts3,$epoch_create_start3,$epoch_create_end3,$epoch_pfcpcreate_end3,$epoch_n1n2_end3,$epoch_pfcpupdate_end3,$epoch_update_end3" >> $csv_op_file

done
for imsi in $(seq -f "%04g" 601 650)
do
    echo "IMSI is - $imsi"

    echo "Transaction is $f1"

    grep_op1=$(cat $amflogFile1 | grep "\[suci-0-208-93-0000-0-0-000000$imsi\] Unknown UE by SUCI" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_regcomp_ts1=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_regcomp_ts1 is - $epoch_regcomp_ts1"

    grep_op1=$(cat $amflogFile1 | grep "UE SUPI\[imsi-20893000000$imsi\] DNN\[internet\] S_NSSAI" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_create_start=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_create_start is - $epoch_create_start"

    grep_op1=$(cat $amflogFile1 | grep "PCS Successfully completed Create transaction with shared UDSF for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_create_end=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_create_end is - $epoch_create_end"

    grep_op1=$(cat $smflogFile1 | grep "PCS Successfully uploaded N4 Create data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_pfcpcreate_end=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_pfcpcreate_end is - $epoch_pfcpcreate_end"

    grep_op1=$(cat $smflogFile1 | grep "PCS Successfully uploading n1-n2 transfer data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_n1n2_end=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_n1n2_end is - $epoch_n1n2_end"

    grep_op1=$(cat $smflogFile1 | grep "PCS Successfully uploaded Update-SM-Context & N4 modify data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_pfcpupdate_end=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_pfcpupdate_end is - $epoch_pfcpupdate_end"

    grep_op1=$(cat $amflogFile1 | grep "PCS Successfully completed Update-SM-Context transaction with shared UDSF for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_update_end=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_update_end is - $epoch_update_end"

    if (( 0 )) ; then

        grep_op1=$(cat $amflogFile1 | grep "\[suci-0-208-93-0000-0-0-000000$imsi\] Unknown UE by SUCI" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
        opfmt=$(echo $utcTs | cut -c 1-)
        epoch_start_ts1=$(date -d "$utcTs" +"%s.%3N")
        echo "epoch_start_ts1 is - $epoch_start_ts1"

        grep_op1=$(cat $amflogFile1 | grep "UE SUPI\[imsi-20893000000$imsi\] DNN[internet] S_NSSAI" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
        opfmt=$(echo $utcTs | cut -c 1-)
        epoch_create_start=$(date -d "$utcTs" +"%s.%3N")
        echo "epoch_create_start is - $epoch_create_start"

        grep_op1=$(cat $smflogFile1 | grep "UE SUPI\[imsi-20893000000$imsi\] DNN[internet] IPv4" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
        opfmt=$(echo $utcTs | cut -c 1-)
        epoch_pfcpcreate_start=$(date -d "$utcTs" +"%s.%3N")
        echo "epoch_pfcpcreate_start is - $epoch_pfcpcreate_start"

        grep_op1=$(cat $amflogFile1 | grep "\[imsi-20893000000$imsi\] Registration complete" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
        opfmt=$(echo $utcTs | cut -c 1-)
        epoch_regcomp_ts1=$(date -d "$utcTs" +"%s.%3N")
        echo "epoch_regcomp_ts1 is - $epoch_regcomp_ts1"

        grep_op1=$(cat $amflogFile1 | grep "PCS Successfully completed n1-n2 transaction with shared UDSF for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
        opfmt=$(echo $utcTs | cut -c 1-)
        epoch_n1n2_ts1=$(date -d "$utcTs" +"%s.%3N")
        echo "epoch_n1n2_ts1 is - $epoch_n1n2_ts1"

        time_diff=$(bc <<< "$epoch_regcomp_ts - $epoch_start_ts")
        echo "For UE with imsi IMSI-20893000000$imsi, Registration time is - $time_diff"
        time_diff=$(bc <<< "$epoch_create_ts - $epoch_regcomp_ts")
        echo "For UE with imsi IMSI-20893000000$imsi, Create time is - $time_diff"
        time_diff=$(bc <<< "$epoch_n1n2_ts - $epoch_create_ts")
        echo "For UE with imsi IMSI-20893000000$imsi, N1-N2 time is - $time_diff"
        time_diff=$(bc <<< "$epoch_update_ts - $epoch_n1n2_ts")
        echo "For UE with imsi IMSI-20893000000$imsi, Update time is - $time_diff"
    

        grep_op1=$(cat $amflogFile1 | grep "PCS Successfully completed Update-SM-Context transaction with shared UDSF for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
        opfmt=$(echo $utcTs | cut -c 1-)
        epoch_update_ts1=$(date -d "$utcTs" +"%s.%3N")
        echo "epoch_update_ts1 is - $epoch_update_ts1"
        
        time_diff1=$(bc <<< "$epoch_update_ts1 - $epoch_start_ts1")
        echo "For UE with imsi IMSI-20893000000$imsi, Total SRE Procedure time is - $time_diff1"

        grep_op1=$(cat $amflogFile2 | grep "\[suci-0-208-93-0000-0-0-000000$imsi\] Unknown UE by SUCI" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
        opfmt=$(echo $utcTs | cut -c 1-)
        epoch_start_ts2=$(date -d "$utcTs" +"%s.%3N")
        echo "epoch_start_ts2 is - $epoch_start_ts2"

        grep_op1=$(cat $amflogFile2 | grep "PCS Successfully uploaded Update-SM-Context data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
        utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
        opfmt=$(echo $utcTs | cut -c 1-)
        epoch_update_ts2=$(date -d "$utcTs" +"%s.%3N")
        echo "epoch_update_ts2 is - $epoch_update_ts2"
        
        time_diff2=$(bc <<< "$epoch_update_ts2 - $epoch_start_ts2")
        echo "For UE with imsi IMSI-20893000000$imsi, Total FTS Procedure time is - $time_diff2"

    fi

    echo "Transaction is $f2"

    grep_op1=$(cat $amflogFile2 | grep "\[suci-0-208-93-0000-0-0-000000$imsi\] Unknown UE by SUCI" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_regcomp_ts2=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_regcomp_ts2 is - $epoch_regcomp_ts2"

    grep_op1=$(cat $amflogFile2 | grep "UE SUPI\[imsi-20893000000$imsi\] DNN\[internet\] S_NSSAI" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_create_start2=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_create_start2 is - $epoch_create_start2"

    grep_op1=$(cat $amflogFile2 | grep "PCS Successfully inserted Create-SM-Context data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_create_end2=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_create_end2 is - $epoch_create_end2"

    grep_op1=$(cat $smflogFile2 | grep "PCS Successfully uploaded N4 Create data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_pfcpcreate_end2=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_pfcpcreate_end2 is - $epoch_pfcpcreate_end2"

    grep_op1=$(cat $smflogFile2 | grep "PCS Successfully uploading n1-n2 transfer data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_n1n2_end2=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_n1n2_end2 is - $epoch_n1n2_end2"

    grep_op1=$(cat $smflogFile2 | grep "PCS Successfully uploaded Update-SM-Context & N4 modify data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_pfcpupdate_end2=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_pfcpupdate_end2 is - $epoch_pfcpupdate_end2"

    grep_op1=$(cat $amflogFile2 | grep "PCS Successfully uploaded Update-SM-Context data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_update_end2=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_update_end2 is - $epoch_update_end2"



    echo "Transaction is $f3"

    grep_op1=$(cat $amflogFile3 | grep "\[suci-0-208-93-0000-0-0-000000$imsi\] Unknown UE by SUCI" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_regcomp_ts3=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_regcomp_ts3 is - $epoch_regcomp_ts3"

    grep_op1=$(cat $amflogFile3 | grep "UE SUPI\[imsi-20893000000$imsi\] DNN\[internet\] S_NSSAI" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_create_start3=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_create_start3 is - $epoch_create_start3"

    grep_op1=$(cat $amflogFile3 | grep "PCS Successfully completed Create transaction with shared UDSF for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_create_end3=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_create_end3 is - $epoch_create_end3"

    grep_op1=$(cat $smflogFile3 | grep "PCS Successfully uploaded N4 Create data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_pfcpcreate_end3=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_pfcpcreate_end3 is - $epoch_pfcpcreate_end3"

    grep_op1=$(cat $smflogFile3 | grep "PCS Successfully uploading n1-n2 transfer data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_n1n2_end3=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_n1n2_end3 is - $epoch_n1n2_end3"

    grep_op1=$(cat $smflogFile3 | grep "PCS Successfully uploaded Update-SM-Context & N4 modify data to MongoDB for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_pfcpupdate_end3=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_pfcpupdate_end3 is - $epoch_pfcpupdate_end3"

    grep_op1=$(cat $amflogFile3 | grep "PCS Successfully completed Update-SM-Context transaction with shared UDSF for supi \[imsi-20893000000$imsi\]" | awk '{print $1,$2}' | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | rev | cut -c 2- | rev)
    utcTs=$(TZ=$commonTZ date -d "$grep_op1 MDT"  +'%T.%3N')
    opfmt=$(echo $utcTs | cut -c 1-)
    epoch_update_end3=$(date -d "$utcTs" +"%s.%3N")
    echo "epoch_update_end3 is - $epoch_update_end3"

    #echo "20893000000$imsi, $time_diff1, $time_diff2" >> $csv_op_file

   echo "20893000000$imsi,$epoch_regcomp_ts1,$epoch_create_start,$epoch_create_end,$epoch_pfcpcreate_end,$epoch_n1n2_end,$epoch_pfcpupdate_end,$epoch_update_end,$epoch_regcomp_ts2,$epoch_create_start2,$epoch_create_end2,$epoch_pfcpcreate_end2,$epoch_n1n2_end2,$epoch_pfcpupdate_end2,$epoch_update_end2,$epoch_regcomp_ts3,$epoch_create_start3,$epoch_create_end3,$epoch_pfcpcreate_end3,$epoch_n1n2_end3,$epoch_pfcpupdate_end3,$epoch_update_end3" >> $csv_op_file 
done
#echo "Mean,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0" >> $csv_op_file
