#!/usr/bin/env bash

# Check if the user provided an input
if [ "$#" -ne 1 ]; then
    echo "Usage: ./step6_register_stake_address.sh <pool_name>"
    return 1
fi

POOL_NAME=$1
echo POOL_NAME: $POOL_NAME

#PAYMENT_KEY_PREFIX=~/keys/utxo-keys/payment
UTXO_KEYS_PATH=~/keys/utxo-keys
POOL_KEYS_PATH=~/keys/pool-keys
TXS_PATH=~/txs

mkdir -p $TXS_PATH


# obtain the "protocol parameters":
#cd $CNODE_HOME/files
cardano-cli query protocol-parameters \
    --testnet-magic 2023 \
    --out-file $CNODE_HOME/files/params.json


# Create a certificate, stake.cert, using the stake.vkey:
#cd $UTXO_KEYS_PATH
cardano-cli stake-address registration-certificate \
    --stake-verification-key-file $UTXO_KEYS_PATH/stake.vkey \
    --out-file $UTXO_KEYS_PATH/stake.cert


# Find your balance and UTXOs.
#cd $TXS_PATH
cardano-cli query utxo --address $(cat $UTXO_KEYS_PATH/payment.addr) --testnet-magic 2023 > $TXS_PATH/fullUtxo1.out
tail -n +3 $TXS_PATH/fullUtxo1.out | sort -k3 -nr > $TXS_PATH/balance1.out
#cat $TXS_PATH/balance1.out

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
done < $TXS_PATH/balance1.out 

txcnt=$(cat $TXS_PATH/balance1.out | wc -l)
echo Total available ADA balance: ${total_balance}
echo Number of UTXOs: ${txcnt}


# Find the amount of the deposit required to register a stake address:
stakeAddressDeposit=$(cat $CNODE_HOME/files/params.json | jq -r '.stakeAddressDeposit')
echo stakeAddressDeposit : $stakeAddressDeposit


# Run the build-raw transaction command:
#    --> The invalid-hereafter value must be greater than the current tip. In this example, we use current slot + 10000:
currentSlot=$(cardano-cli query tip --testnet-magic 2023 | jq -r '.slot')
echo Current Slot: $currentSlot


#cd $UTXO_KEYS_PATH
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat $UTXO_KEYS_PATH/payment.addr)+0 \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee 0 \
    --out-file $TXS_PATH/tx1.tmp \
    --certificate $UTXO_KEYS_PATH/stake.cert



# Calculate the current minimum fee:
#    --> When calculating the fee for a transaction, the --witness-count option indicates the number of keys signing the transaction. 
#    --> You must sign a transaction submitting a stake address registration certificate to the blockchain using the secret—private—key for the payment address spending the input, 
#    --> as well as the secret key for the stake address to register.
#    --> When creating the transaction, ensure that the funds the input contains are greater than the total of the transaction fee and stake address deposit. 
#    --> If funds are insufficient, then the transaction fails.
fee=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file $TXS_PATH/tx1.tmp \
    --tx-in-count ${txcnt} \
    --tx-out-count 1 \
    --testnet-magic 2023 \
    --witness-count 2 \
    --byron-witness-count 0 \
    --protocol-params-file $CNODE_HOME/files/params.json | awk '{ print $1 }')
echo fee: $fee

# Calculate your change output:
txOut=$((${total_balance}-${stakeAddressDeposit}-${fee}))
echo Change Output: ${txOut}

# Build your transaction which will register your stake address:
#cd $UTXO_KEYS_PATH
cardano-cli transaction build-raw \
    ${tx_in} \
    --tx-out $(cat $UTXO_KEYS_PATH/payment.addr)+${txOut} \
    --invalid-hereafter $(( ${currentSlot} + 10000)) \
    --fee ${fee} \
    --certificate-file $UTXO_KEYS_PATH/stake.cert \
    --out-file $TXS_PATH/tx1.raw

# Sign the transaction with both the payment and stake secret keys:
#cd $UTXO_KEYS_PATH
cardano-cli transaction sign \
    --tx-body-file $TXS_PATH/tx1.raw \
    --signing-key-file $UTXO_KEYS_PATH/payment.skey \
    --signing-key-file $UTXO_KEYS_PATH/stake.skey \
    --testnet-magic 2023 \
    --out-file $TXS_PATH/tx1.signed

# Send the signed transaction:
#    --> Output should be aas follows: "Transaction successfully submitted."
#cd $UTXO_KEYS_PATH
cardano-cli transaction submit \
    --tx-file $TXS_PATH/tx1.signed \
    --testnet-magic 2023



