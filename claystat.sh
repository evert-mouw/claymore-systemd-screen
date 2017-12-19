#!/bin/bash

# use the Claymore miner API to get basic information
# ONLY tested with 3 GPUs mining ETH only
# Evert Mouw <post@evert.net>
# 2017-12-10, 2017-12-19

# suggestion: add $0 watch to hourly cron
# (no symlink; needs "watch" argument)

EMAIL="post@evert.net"
WARNMINHASH=16
WARNMINGPU=4
SERVER="localhost"
REBOOTACTION="/opt/claymore/reboot.sh"
SPEAK="yes"

#-----------------------------------------------------

set -euo pipefail
argument=${1:-}

# define variables
declare -a RESULT #array

function main {
	depending
	portchecking
	getting
	#testing
	processing
	case $argument in
		show) showing
			;;
		watch) watchdogging
			;;
		*) echo "Invoke with { show | watch } as argument."
			;;
	esac
}

function depending {
	DEPENDENCIES="netcat jq"
	for DEP in $DEPENDENCIES
	do
		if ! which $DEP > /dev/null
		then
			echo "I need $DEP installed!"
			exit 1
		fi
	done
}

function portchecking {
	if ! netcat -z $SERVER 3333
	then
		local MSG="Could not connect to $SERVER on port 3333"
		echo "$MSG"
		echo "$MSG" | mail -s "#~ Miner $(hostname) DOWN" $EMAIL
		if which notify-send > /dev/null
		then
			notify-send --icon=warn "Miner not running" "$MSG"
		fi
		exit 1
	fi
}

function getting {
	# get the json encoded info using the claymore api
	IFS=$'\n'
	RESULT=($(echo '{"id":0,"jsonrpc":"2.0","method":"miner_getstat1"}' | netcat $SERVER 3333 | jq '{result}'))
}

function testing {
	echo "Variable info:"
	declare -p RESULT

	i=0
	echo "All elements:"
	for e in ${RESULT[@]}
	do
		echo "[$i] $e"
		i=$((i+1))
	done

	echo "4 - totals for ETH: hashrate + shares + rejected shares"
	echo "5 - hashrate per gpu"
	echo "8 - temperature and fan speed(%) pairs for all GPUs."
	echo "9 - current mining pool"
}

function processing {
	LINE4=$(echo ${RESULT[4]} | egrep -o '[0-9]+')
	TOTALHASH=$(echo $LINE4 | cut -d' ' -f1)
	TOTALHASH=$((TOTALHASH/1000))
	TOTALSHARES=$(echo $LINE4 | cut -d' ' -f2)
	TOTALREJECT=$(echo $LINE4 | cut -d' ' -f3)

	LINE5=$(echo ${RESULT[5]} | egrep -o '[0-9]+')
	LINE8=$(echo ${RESULT[8]} | egrep -o '[0-9]+')
	i=0
	for gpu in $LINE5
	do
		GPU_HASH[$i]=$((gpu/1000))
		j=$((i+1))
		FIELDSTART=$((1+(j-1)*2))
		GPU_TEMP[$i]=$(echo $LINE8 | cut -d' ' -f$FIELDSTART)
		GPU_FANP[$i]=$(echo $LINE8 | cut -d' ' -f$((FIELDSTART+1)))
		i=$((i+1))
	done
	GPUCOUNT=$i

	

	LINE9=$(echo ${RESULT[9]} | egrep -o '\".+\"')
	POOL="$LINE9"
}

function showing {
	SUMMARY="Mining Summary"
	SUMMARY="$SUMMARY\nTotal hashrate: $TOTALHASH MHz"
	SUMMARY="$SUMMARY\nMining pool: $POOL"
	SUMMARY="$SUMMARY\nTotal shares accepted: $TOTALSHARES"
	SUMMARY="$SUMMARY\nTotal shares rejected: $TOTALREJECT"
	SUMMARY="$SUMMARY\nNumber of GPUs: $GPUCOUNT"
	echo -e $SUMMARY
	i=0
	NOTIFICATION="gpu\thash\ttemp\tfan"
	while [ $i -lt $GPUCOUNT ]
	do
		echo "GPU $i: ${GPU_HASH[$i]} MHz, ${GPU_TEMP[$i]} degrees C, fan at ${GPU_FANP[$i]} %"
		NOTIFICATION="$NOTIFICATION\n$i\t${GPU_HASH[$i]} MHz\t${GPU_TEMP[$i]} C\t\t${GPU_FANP[$i]} %"
		i=$((i+1))
	done
	if which notify-send > /dev/null
	then
		notify-send --icon=info "Now mining at $TOTALHASH MHz" "\n$NOTIFICATION\n\n$SUMMARY"
	fi
	if [ "$SPEAK" == "yes" ]
	then
		espeak "Informational. Mining at $TOTALHASH megahertz. Counting $GPUCOUNT cards. All normal." 2>/dev/null
	fi
}

function helper_showandmail_slow {
	#echo "$1"
	echo "$1" | mail -s "#! Miner $(hostname) slow" $EMAIL
	if which notify-send > /dev/null
	then
		notify-send --icon=warn "Slow mining" "$1"
	fi
	if [ "$SPEAK" == "yes" ]
	then
		espeak "Warning: mining with low hashrate. $1" 2>/dev/null
	fi
}

function helper_showandmail_gpucount {
	#echo "$1"
	echo "$1" | mail -s "#! Miner $(hostname) GPU missing" $EMAIL
	if which notify-send > /dev/null
	then
		notify-send --icon=warn "Mining error" "$1"
	fi
	if [ "$SPEAK" == "yes" ]
	then
		espeak "Critical warning: GPU missing from miner. $1" 2>/dev/null
	fi
}

function watchdogging {
	i=0
	while [ $i -lt $GPUCOUNT ]
	do
		if [ ${GPU_HASH[$i]} -lt $WARNMINHASH ]
		then
			helper_showandmail_slow "GPU $i hashrate is only ${GPU_HASH[$i]} MHz"
		fi
		i=$((i+1))
	done
	if [ $GPUCOUNT -lt $WARNMINGPU ]
	then
		helper_showandmail_gpucount "Only $GPUCOUNT GPUs active, while $WARNMINGPU were expected."
	fi
	$REBOOTACTION
}

### start running the main loop
main
