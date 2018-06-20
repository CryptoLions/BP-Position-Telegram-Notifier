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


#-- Config ------------------------------

# for what name moniotr position
PRODUCER_NAME_CHECK="cryptolions1"


# Register your Telegram Bot here @BotFather and get your Bot Token like 46354643:JHASDGFJSDJS-dsfdjhf
TELEGRAM_BOT_ID=""

# Users telegram IDS. All who open joined your bot will leave his IDs here  "https://api.telegram.org/bot"+BOT_ID+"/getUpdates"
TELEGRAM_CHAT_IDS=("5111111111" "5222222222")

# time between check system contract in seconds
TIME_BETWEEN_CHECKS=5

# Name of log file
LOG_FILE="log_PlaceMonitor.log"

# Path to you cleos wrapper
CLEOS=/path/to/cleos/cleos.sh


#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
TELEGRAM_API="https://api.telegram.org/bot"
TELEGRAM_SEND_MSG="$TELEGRAM_API$TELEGRAM_BOT_ID/sendMessage"

sendmessage(){
    for i in "${TELEGRAM_CHAT_IDS[@]}"
    do
	curl $TELEGRAM_SEND_MSG -X POST -d 'chat_id='$i'&text='"$1" >/dev/null 2>/dev/null
    done
}


#=====================================================================
#=====================================================================

LAST_POSITION=27;

while true; do

    PROD_LIST=$($CLEOS system listproducers -l 50)
    DATE=`date -d "now" +'%Y.%m.%d %H:%M:%S'`
    POSITION=-1;

    while read -r line
    do
	#echo $line
        POSITION=$(($POSITION+1))

	data=($line)

        NAME=${data[0]};
        PROC=${data[${#data[@]}-1]};

        MSG2="";
        if [[ "$NAME" == "$PRODUCER_NAME_CHECK" ]]; then

	    if [[ $POSITION != $LAST_POSITION && $LAST_POSITION != -1 ]]; then

		SYMBOL="▲"
		if [[ $POSITION > $LAST_POSITION ]]; then
		    SYMBOL="▼"
		fi
		PROC=$(echo $PROC*100 | bc)
		MSG="$SYMBOL $DATE: Position Changed  $LAST_POSITION -> $POSITION  - $PROC %"


		# in case you move to top 21 from standby
    		if [[ $LAST_POSITION -gt 21 && $POSITION -le 21 ]]; then
		    MSG2="✈ Be ready you are in top 21! You will start producing soon (in 2-3 rounds)"
		fi

		# in case you move out from top 21 to standby
    		if [[ $LAST_POSITION -le 21 && $POSITION -gt 21 ]]; then
		    MSG2="💤 your node moved to standby"
		fi


		echo $MSG >> $LOG_FILE


		sendmessage "$MSG"
		if [[ "$MSG2" != "" ]]; then
		    echo $MSG2 >> $LOG_FILE
		    sleep 1
		    sendmessage "$MSG2"
		fi
		#echo "--" >> $LOG_FILE
	    
		LAST_POSITION=$POSITION

		break
	    fi
	fi
    done < <(printf '%s\n' "$PROD_LIST")

    sleep $TIME_BETWEEN_CHECKS;
done






