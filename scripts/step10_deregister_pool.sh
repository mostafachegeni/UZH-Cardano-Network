#!/usr/bin/env bash

# Check if the user provided an input
if [ "$#" -ne 1 ]; then
    echo "Usage: ./step10_deregister_pool.sh <pool_name>"
    return 1
fi

POOL_NAME=$1
echo POOL_NAME: $POOL_NAME

NETWORK_MAGIC=2023

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



CURRENT_EPOCH=$(cardano-cli query tip --testnet-magic $NETWORK_MAGIC | jq '.epoch')
echo current epoch: ${CURRENT_EPOCH}

poolRetireMaxEpoch=$(cat $CNODE_HOME/files//params.json | jq -r '.poolRetireMaxEpoch')
echo poolRetireMaxEpoch: ${poolRetireMaxEpoch}

minRetirementEpoch=$(( ${CURRENT_EPOCH} + 1 ))
maxRetirementEpoch=$(( ${CURRENT_EPOCH} + ${poolRetireMaxEpoch} ))

echo earliest epoch for retirement is: ${minRetirementEpoch}
echo latest epoch for retirement is: ${maxRetirementEpoch}



# Create a stake de-registration certificate:
cardano-cli stake-pool deregistration-certificate \
    --cold-verification-key-file $POOL_KEYS_PATH/node.vkey \
    --epoch $((${CURRENT_EPOCH} + 1)) \
    --out-file $TXS_PATH/pool.dereg


# Find your balance and UTXOs:
#cd $UTXO_KEYS_PATH
cardano-cli query utxo --address $(cat $UTXO_KEYS_PATH/payment.addr) --testnet-magic $NETWORK_MAGIC > $TXS_PATH/fullUtxo4.out
tail -n +3 $TXS_PATH/fullUtxo4.out | sort -k3 -nr > $TXS_PATH/balance4.out
#cat $TXS_PATH/balance4.out

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
done < $TXS_PATH/balance4.out 


txcnt=$(cat $TXS_PATH/balance4.out | wc -l)
echo Total available ADA balance: ${total_balance}
echo Number of UTXOs: ${txcnt}


currentSlot=$(cardano-cli query tip --testnet-magic $NETWORK_MAGIC | jq -r '.slot')
echo Current Slot: $currentSlot



# Build the transaction:
cardano-cli transaction build \
    ${tx_in} \
    --change-address $(cat $UTXO_KEYS_PATH/payment.addr) \
    --testnet-magic $NETWORK_MAGIC \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --certificate-file $TXS_PATH/pool.dereg \
    --witness-override 2 \
    --out-file $TXS_PATH/tx4.raw



# Sign the transaction:
cardano-cli transaction sign \
    --tx-body-file $TXS_PATH/tx4.raw \
    --signing-key-file $UTXO_KEYS_PATH/payment.skey \
    --signing-key-file $POOL_KEYS_PATH/node.skey \
    --testnet-magic $NETWORK_MAGIC  \
    --out-file $TXS_PATH/tx4.signed



echo -n ":::"
cardano-cli transaction txid --tx-file $TXS_PATH/tx4.signed
echo -n ":::"


# Send the transaction:
#    --> Output should be as follows: "Transaction successfully submitted."
cardano-cli transaction submit --tx-file $TXS_PATH/tx4.signed --testnet-magic $NETWORK_MAGIC















