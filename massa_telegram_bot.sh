#!/bin/bash
######################################################
## Massa Telegram Bot
##
##  Send an update about a specified massa account to a telegram channel
##  Inclde the roll cout and balance
##
## Parameters
##  * Postition 1: Massa Address
##
## Notes
##  * The telegram client token and chat ID are located within a 'telegram_secrets' file in the same directory as this script
##    it's content should be...
##        telegram_client_token='super secret'
##        telegram_chat_id='secret(ish)'
##    The file should have appropriate permissions eg chmod 600 telegram_secrets
##  * Run on a schedule using cron (https://www.digitalocean.com/community/tutorials/how-to-use-cron-to-automate-tasks-ubuntu-1804)
##     eg...
##          crontab -e
##          0 * * * * cd /home/xxx/commodum/scripts && ./massa_telegram_bot.sh [MASSA ADDRESS]
#######################################################
massa_address=$1
massa_public_api_uri=http://127.0.0.1:33035

## Query the massa pubilic api to obtain the details for the specified address
address=$(curl --location --request POST "$massa_public_api_uri" \
--header 'Content-Type: application/json' \
--data-raw "{
    \"jsonrpc\": \"2.0\",
    \"id\": 1,
    \"method\": \"get_addresses\",
    \"params\": [[\"$massa_address\"]]
}" )

## Extract the data we're interested in
final_roll_count=$(echo $address | jq ".result[0].final_roll_count")
final_balance=$(echo $address | jq ".result[0].final_balance" | tr -d '"')

echo -e "Roll count: ${final_roll_count}"
echo -e "Ballance: ${final_balance}"

## Read in Telegram secrets
. telegram_secrets

## escape the period in the final balance
escaped_final_balance="${final_balance/./"\\."}"

## Create the message for Telegram
read -r -d '' telegram_message << EOM
*Massa*
Roll count: *$final_roll_count*
Balance: *$escaped_final_balance*
[${massa_address:0:6}\\.\\.\\.${massa_address: -6}](https://massexplo.io/address/$massa_address)
EOM

# Send the message to telegram
curl -s --data "text=$telegram_message" --data "chat_id=$telegram_chat_id" --data "parse_mode=MarkdownV2" 'https://api.telegram.org/bot'$telegram_client_token'/sendMessage'