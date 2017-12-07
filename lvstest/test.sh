if /sbin/ipvsadm -ln | grep FWM; then
	#rules=`/sbin/ipvsadm -ln | sed -n '4,$p' | awk '{print $1" "$2 "\n"}'`
	rules=`/sbin/ipvsadm -ln | sed -n '4,$p' | awk '{print $1" "$2}'`
	ports_fwms=(`/sbin/ipvsadm -ln | sed -n '4,$p' | awk '{print $1" "$2}' | awk '/FWM/ {{printf "%16x", $2} print " "$2}'`)
	ports=(`echo -e "$rules\n" | awk '/FWM/ {print $2}'`)
	#echo ${ports[@]}
	fwms=(`echo -e "$rules\n" | awk '/FWM/ {printf "%16x\n", $2}'`)
	#echo ${fwms[@]}
	#for fwm in `echo ${fwms[@]}`
	#for num in `seq 1 ${#fwms[@]}`
	printf '{\n'
	printf '    "data": [\n'
	for num in `seq 1 2 ${#ports_fwms[@]}`
	do
		fwm=${ports_fwms[$num-1]}
		fwmport=${ports_fwms[$num]}
		nextfwmport=${ports_fwms[$num+2]}
		mark=0x$fwm
		lvsmark="FWM $fwmport"
	#	echo 1 $[ ${#ports_fwms[@]-1} ]
	#	echo 2 $((${#ports_fwms[@]}-1)) $num
		if [ "$((${#ports_fwms[@]}-1))" -eq "$num" ]; then
			nextlvsmark="^$"
			nextmark='^$'
		else
			nextlvsmark="FWM $nextfwmport"
			nextmark=0x${fwms[$num]}
		fi
		protocol_vip=(`iptables -vnxL -t mangle | awk '/'$mark'/ {print $4, $9}'`)
		protocol=${protocol_vip[0]}
		vip=${protocol_vip[1]}
	#	echo "mark" $mark "next" $nextmark
	#	echo "lvsmark" $lvsmark "nextlvs" $nextlvsmark
	#	echo "sed -n '/$lvsmark/,/$nextlvsmark/{//!p}'"
		#echo $rules | sed -n '/'$lvsmark'/,/'$nextlvsmark'/{//!p}'
	#	echo $rules
		#/sbin/ipvsadm -ln | sed -n '4,$p' | awk '{print $1" "$2}' | sed -n '/'"$lvsmark"'/,/'"$nextlvsmark"'/{//!p}'
		realips=(`echo -e "$rules\n" | sed -n '/'"$lvsmark"'/,/'"$nextlvsmark"'/{//!p}' | awk '{print $2}'`)
		#for realip in `echo -e "$rules\n" | sed -n '/'"$lvsmark"'/,/'"$nextlvsmark"'/{//!p}' | awk '{print $2}'`
		for rnum in `seq 1 ${#realips[@]}`
		do
			if [ "$((${#ports_fwms[@]}-1))" -eq "$num" ] && [ "$rnum" -eq "${#realips[@]}" ]; then
				realip=${realips[$rnum-1]}
				printf '        {\n'
		        	#printf "{ \"{#PROTOCOL}\" : \"${protocol}\", \"{#VIP}\" : \"${vip}\", \"{#RIP}\" : \"${realip}\" }"
				echo -e '            "{#PROTOCOL}": '\"${protocol}\"', "{#VIP}": '\"${vip}\"', "{#RIP}": '\"${realip}\"''
		                #echo -e '            "{#SERVICEPORT}": '\"${port[${key}]}\"',\n            "{#NAME}":' \"$1\"
				printf '        }\n'
			else
				realip=${realips[$rnum-1]}
				printf '        {\n'
		        	#printf "{ \"{#PROTOCOL}\" : \"${protocol}\", \"{#VIP}\" : \"${vip}\", \"{#RIP}\" : \"${realip}\" }"
				echo -e '            "{#PROTOCOL}": '\"${protocol}\"', "{#VIP}": '\"${vip}\"', "{#RIP}": '\"${realip}\"''
		                #echo -e '            "{#SERVICEPORT}": '\"${port[${key}]}\"',\n            "{#NAME}":' \"$1\"
				printf '        },\n'
			fi
		done
	done
	printf '    ]\n'
	printf '}\n'
else
	IFS=$'\n'
	TOTAL_LINES=$(sudo /sbin/ipvsadm -Ln |sed -n '4,$p' |awk '{print $1" "$2}' |wc -l)
	LINE_NUM=0
	
	printf '{ "data" : [\n'
	for LINE in $(sudo /sbin/ipvsadm -Ln |sed -n '4,$p' |awk '{print $1" "$2}')
	do
	    LINE_NUM=$(( $LINE_NUM + 1 ))
	    if [ $(echo ${LINE} | awk '{print $1}') = "TCP" -o $(echo ${LINE} | awk '{print $1}') = "UDP" ];then
	        PROTOCOL=$(echo ${LINE} | awk '{print $1}')
	        VIP=$(echo ${LINE} | awk '{print $2}')
	    fi
	    if [ $(echo ${LINE} | awk '{print $1}') = "->" ];then
	        RIP=$(echo ${LINE} | awk '{print $2}')
	        printf "{ \"{#PROTOCOL}\" : \"${PROTOCOL}\", \"{#VIP}\" : \"${VIP}\", \"{#RIP}\" : \"${RIP}\" }"
	        if [ $LINE_NUM != $TOTAL_LINES ];then
	            printf ", \n"
	        fi
	    fi
	done
	printf " ] }\n"
fi
