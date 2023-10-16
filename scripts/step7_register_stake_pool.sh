#!/usr/bin/env bash

# Check if the user provided an input
if [ "$#" -ne 1 ]; then
    echo "Usage: ./step7_register_stake_pool.sh <pool_name>"
    return 1
fi

POOL_NAME=$1
echo POOL_NAME: $POOL_NAME

#PAYMENT_KEY_PREFIX=~/keys/utxo-keys/payment
UTXO_KEYS_PATH=~/keys/utxo-keys
POOL_KEYS_PATH=~/keys/pool-keys
TXS_PATH=~/txs

# Find the minimum pool cost --> (minPoolCost: 340000000):
minPoolCost=$(cat $CNODE_HOME/files/params.json | jq -r .minPoolCost)
echo minPoolCost: ${minPoolCost}


# Create a "registration certificate" for the stake pool:
#    --> Here we are pledging 100 ADA with a fixed pool cost of 345 ADA and a pool margin of 15%.
#cd $POOL_KEYS_PATH
cardano-cli stake-pool registration-certificate \
    --cold-verification-key-file $POOL_KEYS_PATH/node.vkey \
    --vrf-verification-key-file $POOL_KEYS_PATH/vrf.vkey \
    --pool-pledge 1000000000000 \
    --pool-cost 345000000 \
    --pool-margin 0.15 \
    --pool-reward-account-verification-key-file $UTXO_KEYS_PATH/stake.vkey \
    --pool-owner-stake-verification-key-file $UTXO_KEYS_PATH/stake.vkey \
    --testnet-magic 2023 \
    --out-file $POOL_KEYS_PATH/pool.cert


# 16.5. Pledge stake to your stake pool:
#    --> This operation creates a delegation certificate which "delegates" funds from all stake addresses associated with key stake.vkey to the pool belonging to cold key node.vkey.    
#    --> A stake pool owner`s promise to fund their own pool is called Pledge.
#        --> Your balance needs to be greater than the pledge amount.
#        --> You pledge funds are not moved anywhere. In this guide example, the pledge remains in the stake pool owner`s keys, specifically payment.addr
#        --> Failing to fulfill pledge will result in missed block minting opportunities and your delegators would miss rewards.
#        --> Your pledge is not locked up. You are free to transfer your funds.
#cd $POOL_KEYS_PATH
cardano-cli stake-address delegation-certificate \
    --stake-verification-key-file $UTXO_KEYS_PATH/stake.vkey \
    --cold-verification-key-file $POOL_KEYS_PATH/node.vkey \
    --out-file $POOL_KEYS_PATH/deleg.cert


# Find the tip of the blockchain to set the invalid-hereafter parameter properly:
currentSlot=$(cardano-cli query tip --testnet-magic 2023 | jq -r '.slot')
echo Current Slot: $currentSlot


# Find your balance and UTXOs:
#cd $UTXO_KEYS_PATH
cardano-cli query utxo --address $(cat $UTXO_KEYS_PATH/payment.addr) --testnet-magic 2023 > $TXS_PATH/fullUtxo2.out
tail -n +3 $TXS_PATH/fullUtxo2.out | sort -k3 -nr > $TXS_PATH/balance2.out
#cat $TXS_PATH/balance2.out

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
done < $TXS_PATH/balance2.out 


txcnt=$(cat $TXS_PATH/balance2.out | wc -l)
echo Total available ADA balance: ${total_balance}
echo Number of UTXOs: ${txcnt}


# Find the deposit fee for a pool:
stakePoolDeposit=$(cat $CNODE_HOME/files/params.json | jq -r '.stakePoolDeposit')
echo stakePoolDeposit: $stakePoolDeposit


# Run the build-raw transaction command:
#    --> The invalid-hereafter value must be greater than the current tip. In this example, we use current slot + 10000.
#cd $UTXO_KEYS_PATH
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat $UTXO_KEYS_PATH/payment.addr)+$(( ${total_balance} - ${stakePoolDeposit}))  \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --certificate-file $POOL_KEYS_PATH/pool.cert \
    --certificate-file $POOL_KEYS_PATH/deleg.cert \
    --out-file $TXS_PATH/tx2.tmp


# Calculate the minimum fee:
#cd $UTXO_KEYS_PATH
fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file $TXS_PATH/tx2.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --testnet-magic 2023 \
    --witness-count 3 \
    --byron-witness-count 0 \
    --protocol-params-file $CNODE_HOME/files/params.json | awk '{ print $1 }')
echo fee: $fee


# Calculate your change output:
txOut=$((${total_balance}-${stakePoolDeposit}-${fee}))
echo txOut: ${txOut}


# Build the transaction:
#cd $UTXO_KEYS_PATH
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat $UTXO_KEYS_PATH/payment.addr)+${txOut} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --certificate-file $POOL_KEYS_PATH/pool.cert \
    --certificate-file $POOL_KEYS_PATH/deleg.cert \
    --out-file $TXS_PATH/tx2.raw


# Sign the transaction:
#cd $UTXO_KEYS_PATH
cardano-cli transaction sign \
    --tx-body-file $TXS_PATH/tx2.raw \
    --signing-key-file $UTXO_KEYS_PATH/payment.skey \
    --signing-key-file $POOL_KEYS_PATH/node.skey \
    --signing-key-file $UTXO_KEYS_PATH/stake.skey \
    --testnet-magic 2023 \
    --out-file $TXS_PATH/tx2.signed


# Send the transaction:
#    --> Output should be aas follows: "Transaction successfully submitted."
cardano-cli transaction submit \
    --tx-file $TXS_PATH/tx2.signed \
    --testnet-magic 2023



