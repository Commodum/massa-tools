#!/bin/bash
######################################################
## Auto buy rolls
##
## Buy extra rolls if the amount of massa for an address exceeds the roll price
##
## Parameters
##  * Postition 1 - Massa Address
##
## Exampe
##  * ./auto_roll.sh AU12345789012345678901234567890123456789012345678901D
##
## Notes:
##  * The password for the wallet is located within a 'wallet_password' file in the same directory as this script
##    it's content should be...
##        WALLET_PASSWORD='super secret'
##    The file should have appropriate permissions eg chmod 600 wallet_password
##  * Run on a schedule using cron (https://www.digitalocean.com/community/tutorials/how-to-use-cron-to-automate-tasks-ubuntu-1804)
##     eg...
##          crontab -e
##          0 * * * * cd /home/xxx/massa/massa-client && ./auto_roll.sh [MASSA ADDRESS] >> /home/xxx/massa/massa-client/auto_roll.log
#######################################################
address=$1
massa_client_path='/home/ian/massa-binaries/versions/current/massa/massa-client'
massa_wallet_location='/home/ian/massa-binaries/wallets/'
roll_price=100

## Read in the Wallet Password
. wallet_password

## Get the addresses from the wallet
cd $massa_client_path
wallet=$(eval "./massa-client wallet_info --json --wallet \"$massa_wallet_location\" --pwd \"$WALLET_PASSWORD\"")

## extract the balance for the account from the wallet
final_price=$(echo $wallet | jq ".$address.address_info.final_balance" | tr -d '"')

## calculate how many rolls we can buy
rolls=$(bc -l <<<"scale=0; $final_price/$roll_price")

## If we can afford some, buy some wallets
current_date_time=$(date --utc)
if [ "$rolls" -gt 0 ]; then
        #echo -e "${current_date_time}: Balance: ${final_price}"
        #echo -e "${current_date_time}: Buyable: ${rolls}"
        echo -e "${current_date_time}: ${address} : Balance ${final_price} : Buyable ${rolls}"
        echo -e $(eval "./massa-client buy_rolls --wallet \"$massa_wallet_location\" --pwd \"$WALLET_PASSWORD\" ${address} ${rolls} 0")
else
        echo -e "${current_date_time}: ${address} : Balance ${final_price}"
fi