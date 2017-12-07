#!/bin/bash
# liu

# 判断lvs是否使用了fwmark
if /sbin/ipvsadm -ln | grep FWM &> /dev/null; then
	# 获取lvs列表
	rules=`/sbin/ipvsadm -ln | sed -n '4,$p' | awk '{print $1" "$2}'`
	# 获取fwmark名并进行16进制转码, 存入数组
	ports_fwms=(`/sbin/ipvsadm -ln | sed -n '4,$p' | awk '{print $1" "$2}' | awk '/FWM/ {{printf "%16x", $2} print " "$2}'`)
	## 拆分ports_fwms
	#ports=(`echo -e "$rules\n" | awk '/FWM/ {print $2}'`)
	#fwms=(`echo -e "$rules\n" | awk '/FWM/ {printf "%16x\n", $2}'`)
	# json报头
	printf '{\n'
	printf '    "data": [\n'
	# 获取fwmark及对应10进制mark
	for num in `seq 1 2 ${#ports_fwms[@]}`
	do
		fwmport=${ports_fwms[$num]}
		nextfwmport=${ports_fwms[$num+2]}
		fwm=${ports_fwms[$num-1]}
		mark=0x$fwm
		lvsmark="FWM $fwmport"
		# 判断是否数组中最后一个组, 是则设置sed终止符
		if [ "$((${#ports_fwms[@]}-1))" -eq "$num" ]; then
			nextlvsmark="^$"
			nextmark='^$'
		else
			nextlvsmark="FWM $nextfwmport"
			nextmark=0x${fwms[$num]}
		fi
		# 通过fwmark规则获取使用的vip与协议
		protocol_vip=(`iptables -vnxL -t mangle | awk '/'$mark'/ {print $4, $9}'`)
		protocol=`echo ${protocol_vip[0]} | tr [a-z] [A-Z]`
		vip=${protocol_vip[1]}
		# 通过前面条件获取ipvsadm规则分组
		realips=(`echo -e "$rules\n" | sed -n '/'"$lvsmark"'/,/'"$nextlvsmark"'/{//!p}' | awk '{print $2}'`)
		for rnum in `seq 1 ${#realips[@]}`
		do
			# 判定是否内/外循环的最后一个循环
			if [ "$((${#ports_fwms[@]}-1))" -eq "$num" ] && [ "$rnum" -eq "${#realips[@]}" ]; then
				realip=${realips[$rnum-1]}
				printf '        {\n'
				echo -e '            "{#PROTOCOL}": '\"${protocol}\"', "{#VIP}": '\"${vip}\"', "{#RIP}": '\"${realip}\"''
				printf '        }\n'
			else
				realip=${realips[$rnum-1]}
				printf '        {\n'
				echo -e '            "{#PROTOCOL}": '\"${protocol}\"', "{#VIP}": '\"${vip}\"', "{#RIP}": '\"${realip}\"''
				printf '        },\n'
			fi
		done
	done
	# 报文尾部
	printf '    ]\n'
	printf '}\n'
else
	# 常规lvs规则获取
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
