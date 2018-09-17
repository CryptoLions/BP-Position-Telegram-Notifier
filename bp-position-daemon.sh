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
LAST_POSITION=30;

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


getVoteWeight(){
    timestamp_epoch=946684800
    now="$(date +%s)"
    let "dates_=$now-$timestamp_epoch"
    let "weight_=$dates_/(86400*7)"
    weight=$(bc <<< "scale=16;$weight_/52")
    res=$(bc -l <<< "e($weight*l(2))")
    echo $res
}
#=====================================================================
#=====================================================================
LAST_EOS_VOTES=0;

while true; do

    DATE=`date -d "now" +'%Y.%m.%d %H:%M:%S'`
	POSITION=0;

	PROD_LIST=$($CLEOS system listproducers -l 50 -j)

	VOTE_WEIGHT=$(getVoteWeight)
	TOTAL_VOTE_WEIGHT=$(echo $PROD_LIST | jq -r '.total_producer_vote_weight' | cut -f1 -d".")

	for row in $(echo "${PROD_LIST}" | jq -r '.rows[] | @base64'); do
		_jq() {
			echo ${row} | base64 --decode | jq -r ${1}
		}

		NAME=$(_jq '.owner')
		TOTAL_VOTES=$(_jq '.total_votes' | cut -f1 -d".")
		PROC=$(bc <<< "scale=3; $TOTAL_VOTES*100/$TOTAL_VOTE_WEIGHT")

		EOS_VOTES=$(bc <<< "scale=2; $TOTAL_VOTES/$VOTE_WEIGHT/10000")
		EOS_VOTES_NICE=$(echo $EOS_VOTES | sed ':a;s/\B[0-9]\{3\}\>/ &/;ta')

        	POSITION=$(($POSITION+1))

        	MSG2="";
        	if [[ "$NAME" == "$PRODUCER_NAME_CHECK" ]]; then
	    		if [[ $POSITION != $LAST_POSITION && $LAST_POSITION != -1 ]]; then

				SYMBOL="▲"
				if [[ $POSITION > $LAST_POSITION ]]; then
			    	SYMBOL="▼"
				fi
				MSG="$SYMBOL $DATE: Position Changed  $LAST_POSITION -> $POSITION - $PROC% %0A $EOS_VOTES_NICE EOS"


				# in case you move to top 21 from standby
	    		if [[ $LAST_POSITION -gt 21 && $POSITION -le 21 ]]; then
			    	MSG2="✈ Be ready you are in top 21! You will start producing soon (in 2-3 rounds)"
				fi

				# in case you move out from top 21 to standby
		    	if [[ $LAST_POSITION -le 21 && $POSITION -gt 21 ]]; then
				    MSG2="💤 your node moved to stadnby"
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

			if [[ $LAST_EOS_VOTES == 0 ]]; then
				LAST_EOS_VOTES=$EOS_VOTES;
			fi

		    if [[ $LAST_EOS_VOTES != $EOS_VOTES && $LAST_EOS_VOTES > 0 ]]; then
    			DIFF=$(bc <<< "$EOS_VOTES - $LAST_EOS_VOTES");
                if (( $(echo "$DIFF > 0" |bc -l) )); then
					SYM="✚"
                else
                	SYM="▬ "
                	DIFF=$(bc <<< "scale=2;-1*$DIFF")
                fi

                DIFF_NICE=$(echo $DIFF | sed ':a;s/\B[0-9]\{3\}\>/ &/;ta')

                MSG="$SYM$DIFF_NICE EOS Votes = $EOS_VOTES_NICE EOS";
                sendmessage "$MSG"

    			LAST_EOS_VOTES=$EOS_VOTES
		    fi
		fi
	done

    sleep $TIME_BETWEEN_CHECKS;
done




