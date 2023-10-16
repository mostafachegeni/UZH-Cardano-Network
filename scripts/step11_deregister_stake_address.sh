#!/usr/bin/env bash

# Check if the user provided an input
if [ "$#" -ne 1 ]; then
    echo "Usage: ./step11_deregister_stake_address.sh <pool_name>"
    return 1
fi

POOL_NAME=$1
echo POOL_NAME: $POOL_NAME

NETWORK_MAGIC=2023
FAUCET_ADDR=addr_test1qpr7re7v528ctujqdsehkvz4kre8440mqsmuqvw28h4xgpkaqfxd60wc84tu7nvqlwqvm6j3e3kewmkethu43pryt2sscrcchz

#PAYMENT_KEY_PREFIX=~/keys/utxo-keys/payment
UTXO_KEYS_PATH=~/keys/utxo-keys
POOL_KEYS_PATH=~/keys/pool-keys
TXS_PATH=~/txs


# Blochchain must be synced !
SYNC=$(cardano-cli query tip --testnet-magic $NETWORK_MAGIC | jq '.syncProgress')

if [ $SYNC != "\"100.00\"" ]; then
    echo -e "\nsyncProgress: $SYNC ... please wait for the node to sync and then try again.\n"
    return 1
fi


cardano-cli stake-address deregistration-certificate \
    --stake-verification-key-file $UTXO_KEYS_PATH/stake.vkey \
    --out-file $TXS_PATH/stake.dereg


# Find your balance and UTXOs:
#cd $UTXO_KEYS_PATH
cardano-cli query utxo --address $(cat $UTXO_KEYS_PATH/payment.addr) --testnet-magic $NETWORK_MAGIC > $TXS_PATH/fullUtxo5.out
tail -n +3 $TXS_PATH/fullUtxo5.out | sort -k3 -nr > $TXS_PATH/balance5.out
#cat $TXS_PATH/balance5.out


tx_in=""
total_balance=0
while read -r utxo; do 
    #type=$(awk '{ print $6 }' <<< "${utxo}") 
    #if [[ ${type} == 'TxOutDatumNone' ]] 
    #then 
        in_addr=$(awk '{ print $1 }' <<< "${utxo}") 
        idx=$(awk '{ print $2 }' <<< "${utxo}") 
        utxo_balance=$(awk '{ print $3 }' <<< "${utxo}") 
        total_balance=$((${total_balance}+${utxo_balance})) 
        echo TxHash: ${in_addr}#${idx} 
        echo ADA: ${utxo_balance} 
        tx_in="${tx_in} --tx-in ${in_addr}#${idx}" 
    #fi 
done < $TXS_PATH/balance5.out 


txcnt=$(cat $TXS_PATH/balance5.out | wc -l)
echo Total available ADA balance: ${total_balance}
echo Number of UTXOs: ${txcnt}



stakePoolRewards=$(cardano-cli query stake-address-info --testnet-magic 2023 --address $(cat $UTXO_KEYS_PATH/stake.addr) | jq -r '.[0].rewardAccountBalance')
echo stakePoolRewards: $stakePoolRewards

currentSlot=$(cardano-cli query tip --testnet-magic $NETWORK_MAGIC | jq -r '.slot')
echo Current Slot: $currentSlot

keyDeposit=$(cardano-cli query protocol-parameters   --cardano-mode   --testnet-magic $NETWORK_MAGIC | jq '.stakeAddressDeposit')
echo key deposit: $keyDeposit



FAUCET_AMOUNT=200000000000000

# Build the transaction:
cardano-cli transaction build \
    ${tx_in} \
    --tx-out $FAUCET_ADDR+$FAUCET_AMOUNT \
    --change-address $(cat $UTXO_KEYS_PATH/payment.addr) \
    --testnet-magic $NETWORK_MAGIC \
    --withdrawal $(cat $UTXO_KEYS_PATH/stake.addr)+$(( ${stakePoolRewards} )) \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --certificate-file $TXS_PATH/stake.dereg \
    --out-file $TXS_PATH/tx_faucet.raw


# Sign the transaction:
cardano-cli transaction sign \
    --tx-body-file $TXS_PATH/tx_faucet.raw \
    --signing-key-file $UTXO_KEYS_PATH/payment.skey \
    --signing-key-file $UTXO_KEYS_PATH/stake.skey \
    --testnet-magic $NETWORK_MAGIC  \
    --out-file $TXS_PATH/tx_faucet.signed


echo -n ":::"
cardano-cli transaction txid --tx-file $TXS_PATH/tx_faucet.signed
echo -n ":::"


# Send the transaction:
#    --> Output should be as follows: "Transaction successfully submitted."
cardano-cli transaction submit --tx-file $TXS_PATH/tx_faucet.signed --testnet-magic $NETWORK_MAGIC


