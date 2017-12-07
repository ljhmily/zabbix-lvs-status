#!/bin/bash
#filename: lvs_discovery.sh
#author: YuanBinbin
MY_KEY=(`sudo /sbin/ipvsadm -L -n |egrep -v 'TCP|UDP|Virtual|LocalAddress|ActiveConn' |grep  "$1"|awk '$6 > 0 {print $2}'`)
length=${#MY_KEY[@]}
printf "{\n"
printf  '\t'"\"data\":["
for ((i=0;i<$length;i++))
do     
        printf '\n\t\t{'
        printf "\"{#IFNAME}\":\"${MY_KEY[$i]}\"}"
        if [ $i -lt $[$length-1] ];then
                printf ','
        fi
done
printf  "]}\n"
