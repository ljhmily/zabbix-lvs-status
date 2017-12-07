#!/bin/bash
# liu

function=$1
realip=$4

# 判断是否使用了fwmark
if /sbin/ipvsadm -ln | grep FWM &> /dev/null; then
	protocol='FWM  '
	fwm='.'`echo $4 | awk -F':' '{print $2}'`' '
else
	protocol=$2
	fwm=$3
fi

# 所有选项条件比对实现
# 将所有选项放入数组
rules=(ActiveConn InActConn CPS InPPS OutPPS InBPS OutBPS)
summary=(TotalConn TotalActConn TotalInActConn TotalInPkts TotalOutPkts TotalInBytes TotalOutBytes)
# 判断输入元素是否在数组中
if [[ ${rules[@]} =~ $1 ]]; then
	# 获取元素下标
	num=$((`xargs -n1 <<< ${rules[*]} | sed -n '/^'$1'$/='`-1))
	# 根据选项不同, 拆分命令
	if [[ $num -le 1 ]]; then
		sudo /sbin/ipvsadm -Ln | sed -n "/$protocol$fwm/,/$realip/p" | tail -n 1 | awk '{print $'$(($num+5))'}'
	else
		sudo /sbin/ipvsadm -Ln --rate | sed -n "/$protocol$fwm/,/$realip/p" | tail -n 1 | awk '{print $'$(($num+1))'}'
	fi
elif [[ ${summary[@]} =~ $1 ]]; then
	num=$((`xargs -n1 <<< ${summary[*]} | sed -n '/^'$1'$/='`-1))
	# 获取每秒转发的包的数量及每秒转发的流量
	#tail -1 /proc/net/ip_vs_stats | awk '{print strtonum("0x"$1), strtonum("0x"$2), strtonum("0x"$3), strtonum("0x"$4), strtonum("0x"$5)}' | awk '{print $2" "$4}'
	# 获取会话连接数
	#wc -l /proc/net/ip_vs_conn
	if [[ $num -eq 0 ]]; then
		wc -l /proc/net/ip_vs_conn | awk '{print $1}'
	elif [[ $num -le 2 ]]; then
		sudo /sbin/ipvsadm -ln | sed -n '1,3d;p' | awk '{sum+=$'$(($num+4))'}END{print sum}'
	elif [[ $num -ge 3 ]] && [[ $num -le 6 ]]; then
		tail -1 /proc/net/ip_vs_stats | awk '{print strtonum("0x"$1), strtonum("0x"$2), strtonum("0x"$3), strtonum("0x"$4), strtonum("0x"$5)}' | awk '{print $'$(($num-1))'}'
	fi
else
	exit
fi

# 每个选项分函数实现
#function ActiveConn {
#    sudo /sbin/ipvsadm -Ln |sed -n "/$1  $2/,/$3/p" |tail -n 1 |awk '{print $5}'
#}
#function InActConn {
#    sudo /sbin/ipvsadm -Ln |sed -n "/$1  $2/,/$3/p" |tail -n 1 |awk '{print $6}'
#}
#function CPS {
#    sudo /sbin/ipvsadm -Ln --rate |sed -n "/$1  $2/,/$3/p" |tail -n 1 |awk '{print $3}'
#}
#function InPPS {
#    sudo /sbin/ipvsadm -Ln --rate |sed -n "/$1  $2/,/$3/p" |tail -n 1 |awk '{print $4}'
#}
#function OutPPS {
#    sudo /sbin/ipvsadm -Ln --rate |sed -n "/$1  $2/,/$3/p" |tail -n 1 |awk '{print $5}'
#}
#function InBPS {
#    sudo /sbin/ipvsadm -Ln --rate |sed -n "/$1  $2/,/$3/p" |tail -n 1 |awk '{print $6}'
#}
#function OutBPS {
#    sudo /sbin/ipvsadm -Ln --rate |sed -n "/$1  $2/,/$3/p" |tail -n 1 |awk '{print $7}'
#}
#
#$function $protocol $fwm $realip


# 所有选项for循环实现, 未完成(麻烦)
#for i in `seq 1 ${#rules[@]}`
#do
#	# xargs -n1 <<<${rules[*]} | sed -n '/^4$/='
#	if [ ${rules[i-1]} -eq ActiveConn ] || [ ${rules[i-1]} -eq InActConn ]; then
#		#sudo /sbin/ipvsadm -Ln |sed -n "/$1  $2/,/$3/p" |tail -n 1 |awk '{print $5}'
#		sudo /sbin/ipvsadm -Ln |sed -n "/$1  $2/,/$3/p" |tail -n 1 |awk '{print "'$i+5'"}'
#	fi
#done
#
