#!/usr/bin/env bash

set -euo pipefail

cd $CNODE_HOME
mkdir -p output

FAUCET_AMOUNT=$1
SEND_ADDR=$2

NETWORK_MAGIC=2023
UTXO_KEYS_PATH=~/keys/utxo-keys
POOL_KEYS_PATH=~/keys/pool-keys
TXS_PATH=~/txs

mkdir -p $TXS_PATH

# Find your balance and UTXOs:
cardano-cli query utxo --address $(cat $UTXO_KEYS_PATH/payment.addr) --testnet-magic 2023 > $TXS_PATH/fullUtxo_faucet.out
tail -n +3 $TXS_PATH/fullUtxo_faucet.out | sort -k3 -nr > $TXS_PATH/balance_faucet.out
cat $TXS_PATH/balance_faucet.out
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
done < $TXS_PATH/balance_faucet.out 

txcnt=$(cat $TXS_PATH/balance_faucet.out | wc -l)
echo Total available ADA balance: ${total_balance}
echo Number of UTXOs: ${txcnt}





#ADDR=$(cat $CNODE_HOME/initial-keys/utxo1.addr)
#ADDR_AMOUNT=$(cardano-cli query utxo --address $ADDR --testnet-magic $NETWORK_MAGIC | awk '{if(NR==3) print $3}')
#UTXO=$(cardano-cli query utxo --address $ADDR --testnet-magic $NETWORK_MAGIC | awk '{if(NR==3) print $1 "#" $2}')

cardano-cli transaction build \
    ${tx_in} \
    --tx-out $SEND_ADDR+$FAUCET_AMOUNT \
    --change-address $(cat $UTXO_KEYS_PATH/payment.addr) \
    --testnet-magic $NETWORK_MAGIC \
    --out-file $TXS_PATH/tx_faucet.raw


cardano-cli transaction sign \
    --tx-body-file $TXS_PATH/tx_faucet.raw \
    --out-file $TXS_PATH/tx_faucet.signed \
    --signing-key-file $UTXO_KEYS_PATH/payment.skey

echo -n ":::"
cardano-cli transaction txid --tx-file $TXS_PATH/tx_faucet.signed
echo -n ":::"

cardano-cli transaction submit --tx-file $TXS_PATH/tx_faucet.signed --testnet-magic $NETWORK_MAGIC

rm $TXS_PATH/tx_faucet.raw
mv $TXS_PATH/tx_faucet.signed $TXS_PATH/tx_faucet.sent
