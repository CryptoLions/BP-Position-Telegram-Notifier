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

DATADIR="./"

./stop.sh
./bp-position-daemon.sh & echo $! > $DATADIR/placeChecker.pid

