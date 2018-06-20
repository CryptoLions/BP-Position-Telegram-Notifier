#!/bin/bash
################################################################################
#
# EOS BP Position Monitor
# Daemon that sends pm in telegram using bot functionality on changing position
#
# Created by http://CryptoLions.io
#
# Git Hub: https://github.com/CryptoLions/BP-Position-Telegram-Notifier
# Eos Network Monitor: http://eosnetworkmonitor.io/
#
###############################################################################

DIR="./"


    if [ -f $DIR"/placeChecker.pid" ]; then
	pid=`cat $DIR"/placeChecker.pid"`
	echo $pid
	kill $pid
	rm -r $DIR"/placeChecker.pid"
	
	echo -ne "Stoping Daemon"

        while true; do
            [ ! -d "/proc/$pid/fd" ] && break
            echo -ne "."
            sleep 1
        done
        echo -ne "\rDaemon Stopped.    \n"
    fi

