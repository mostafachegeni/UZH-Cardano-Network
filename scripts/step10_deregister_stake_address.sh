#!/usr/bin/env bash

# Check if the user provided an input
if [ "$#" -ne 1 ]; then
    echo "Usage: ./step10_deregister_stake_address.sh <pool_name>"
    return 1
fi

POOL_NAME=$1
echo POOL_NAME: $POOL_NAME

NETWORK_MAGIC=2023
FAUCET_ADDR=addr_test1qztc80na8320zymhjekl40yjsnxkcvhu58x59mc2fuwvgkls6c2fnu8cyfjfxljyvpwt5qamtyrzl69zyva308y0vntsfhv6r9

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




# Draft the "withdraw + deregistration" transaction to transfer the rewards to a payment address:
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $FAUCET_ADDR+$(( ${total_balance} + ${stakePoolRewards} +${keyDeposit} ))  \
    --withdrawal $(cat $UTXO_KEYS_PATH/stake.addr)+$(( ${stakePoolRewards} )) \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --certificate-file $TXS_PATH/stake.dereg \
    --out-file $TXS_PATH/tx5.tmp


fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file $TXS_PATH/tx5.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --testnet-magic $NETWORK_MAGIC \
    --witness-count 2 \
    --byron-witness-count 0 \
    --protocol-params-file $CNODE_HOME/files/params.json | awk '{ print $1 }')
echo fee: $fee


txOut=$((${total_balance}-${fee}+${stakePoolRewards}+${keyDeposit}))
echo txOut: ${txOut}


# Build the transaction:
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $FAUCET_ADDR+${txOut} \
    --withdrawal $(cat $UTXO_KEYS_PATH/stake.addr)+${stakePoolRewards} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --certificate-file $TXS_PATH/stake.dereg \
    --out-file $TXS_PATH/tx5.raw



# Sign the transaction:
cardano-cli transaction sign \
    --tx-body-file $TXS_PATH/tx5.raw \
    --signing-key-file $UTXO_KEYS_PATH/payment.skey \
    --signing-key-file $UTXO_KEYS_PATH/stake.skey \
    --testnet-magic $NETWORK_MAGIC  \
    --out-file $TXS_PATH/tx5.signed




# Send the transaction:
#    --> Output should be aas follows: "Transaction successfully submitted."
cardano-cli transaction submit \
    --tx-file $TXS_PATH/tx5.signed \
    --testnet-magic $NETWORK_MAGIC 

