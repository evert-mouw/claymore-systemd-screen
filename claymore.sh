#!/bin/sh

# starts or stops the claymore miner in a screen
# run from rc.local using $0 start screen
# or use the systemd service file

# systemd notes:
# sudo cp claymore.service /etc/systemd/system/
# sudo systemctl enable claymore
# beware of the PIDFILE location ;)

# Evert Mouw <post@evert.net>
# 2017-12-11

## Arch Linux specific
## installed libcurl-compat and
## needs env "LD_PRELOAD=libcurl.so.4.0.0"
## https://github.com/nanopool/Claymore-Dual-Miner/issues/10

## Optimizations are from:
## https://www.reddit.com/r/EtherMining/comments/6b9vcu/need_help_rx580_dual_mining_bios_modding_and/
## Note: -tstop is configured to prevent overheating

PIDFILE="/var/run/claymorescreen.pid"
BINARY="/opt/claymore/ethdcrminer64"
ACCOUNT="-epool eth-eu.dwarfpool.com:8008 -ewal 0x20843145b36b5e7415c4243ee4cd23aea4df750d/regin/post@evert.net -epsw post@evert.net"
OPTIMIZATIONS="-epsw x -esm 0 -estale 0 -mode 1 -asm 1 -dcri 9 -cclock 1200 -cvddc 900 -mclock 2250 -mvddc 850 -tstop 85 -tt 65 -fanmin 25 -fanmax 100"
EMAIL="post@evert.net"

## environment variables
## use sudo with -E or --preserve-env
#*segfault!*#export GPU_FORCE_64BIT_PTR=0
export GPU_MAX_HEAP_SIZE=100
export GPU_USE_SYNC_OBJECTS=1
export GPU_MAX_ALLOC_PERCENT=100
export GPU_SINGLE_ALLOC_PERCENT=100

MINERBIN=$(basename $BINARY)

# First test sudo rights (kenorb, 2014).
if timeout 2 sudo id > /dev/null
then
	echo "Yes, we can sudo :-)"
else
	echo "You need sudo rights."
	exit 1
fi

# If "stop" option is given, kill the process
if [ "$1" == "stop" ]
then
	echo "Stopping the miner with signal 2 (ctrl-q)"
	pkill -2 $MINERBIN
	sleep 2
	if pidof $BINARY > /dev/null
	then
		killall $MINERBIN
	fi
	if [ -e $PIDFILE ]
	then
		rm $PIDFILE
	fi
	exit
fi

# Start the miner
if [ "$1" == "start" ]
then
	MSG=""
	echo "Starting the miner!"
	if [ "$2" == "screen" ]
	then
		echo "(in a detached screen)"
		PREFIX="screen -dm -S clay"
		MSG="Detached screen session loaded while "
	fi
	$PREFIX sudo -E env "LD_PRELOAD=libcurl.so.4.0.0" $BINARY $ACCOUNT $OPTIMIZATIONS
	MSG="$MSG starting the miner :-)" | mail -s "#~ Miner started on $(hostname)" $EMAIL
	if [ "$2" == "screen" ]
	then
		sleep 1
		PID=$(screen -list | grep clay | egrep -o [0-9]+)
		echo "$PID" > $PIDFILE
	fi
	exit
fi

# Get process
if [ "$1" == "status" ]
then
	if pidof $BINARY > /dev/null
	then
		echo "PIDs of running miner $MINERBIN (started)"
		pidof $MINERBIN
		echo "Active screen sessions:"
		screen -list | grep clay
		echo "From API running on port 3333"
	else
		"$MINERBIN not running (stopped)"
	fi
	exit
fi

# Help
if [ "$1" == "help" ]
then
	echo "Run $0 with one of these arguments:"
	echo "start | stop | status | help"
	exit
fi

# case else...

