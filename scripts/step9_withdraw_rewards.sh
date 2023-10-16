#!/usr/bin/env bash

# Check if the user provided an input
if [ "$#" -ne 1 ]; then
    echo "Usage: ./step9_withdraw_rewards.sh <pool_name>"
    return 1
fi

POOL_NAME=$1
echo POOL_NAME: $POOL_NAME

#PAYMENT_KEY_PREFIX=~/keys/utxo-keys/payment
UTXO_KEYS_PATH=~/keys/utxo-keys
POOL_KEYS_PATH=~/keys/pool-keys
TXS_PATH=~/txs

stakePoolRewards=$(cardano-cli query stake-address-info --testnet-magic 2023 --address $(cat $UTXO_KEYS_PATH/stake.addr) | jq -r '.[0].rewardAccountBalance')
echo stakePoolRewards: $stakePoolRewards


# Find the tip of the blockchain to set the invalid-hereafter parameter properly:
currentSlot=$(cardano-cli query tip --testnet-magic 2023 | jq -r '.slot')
echo Current Slot: $currentSlot


# Find your balance and UTXOs:
cardano-cli query utxo --address $(cat $UTXO_KEYS_PATH/payment.addr) --testnet-magic 2023 > $TXS_PATH/fullUtxo3.out
tail -n +3 $TXS_PATH/fullUtxo3.out | sort -k3 -nr > $TXS_PATH/balance3.out
cat $TXS_PATH/balance3.out
tx_in=""
total_balance=0
while read -r utxo; do 
    type=$(awk '{ print $6 }' <<< "${utxo}") 
    if [[ ${type} == 'TxOutDatumNone' ]] 
    then 
        in_addr=$(awk '{ print $1 }' <<< "${utxo}") 
        idx=$(awk '{ print $2 }' <<< "${utxo}") 
        utxo_balance=$(awk '{ print $3 }' <<< "${utxo}") 
        total_balance=$((${total_balance}+${utxo_balance})) 
        echo TxHash: ${in_addr}#${idx} 
        echo ADA: ${utxo_balance} 
        tx_in="${tx_in} --tx-in ${in_addr}#${idx}" 
    fi 
done < $TXS_PATH/balance3.out 

txcnt=$(cat $TXS_PATH/balance3.out | wc -l)
echo Total available ADA balance: ${total_balance}
echo Number of UTXOs: ${txcnt}


# Draft the withdraw transaction to transfer the rewards to a payment address:
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat $UTXO_KEYS_PATH/payment.addr)+$(( ${total_balance} + ${stakePoolRewards} ))  \
    --withdrawal $(cat $UTXO_KEYS_PATH/stake.addr)+0 \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --out-file $TXS_PATH/tx3.tmp



# Calculate the minimum fee:
fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file $TXS_PATH/tx3.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --witness-count 3 \
    --byron-witness-count 0 \
    --testnet-magic 2023 \
    --protocol-params-file $CNODE_HOME/files/params.json | awk '{ print $1 }')
echo fee: $fee


# Calculate the output value:
txOut=$((${total_balance}+${stakePoolRewards}-${fee}))
echo txOut: ${txOut}


# Build the transaction:
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat $UTXO_KEYS_PATH/payment.addr)+${txOut} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --withdrawal $(cat $UTXO_KEYS_PATH/stake.addr)+${stakePoolRewards} \
    --fee ${fee} \
    --out-file $TXS_PATH/tx3.raw



# Sign the transaction:
cardano-cli transaction sign \
    --tx-body-file $TXS_PATH/tx3.raw \
    --signing-key-file $UTXO_KEYS_PATH/payment.skey \
    --signing-key-file $UTXO_KEYS_PATH/stake.skey \
    --testnet-magic 2023 \
    --out-file $TXS_PATH/tx3.signed



# Send the transaction:
#    --> Output should be aas follows: "Transaction successfully submitted."
cardano-cli transaction submit \
    --tx-file $TXS_PATH/tx3.signed \
    --testnet-magic 2023


