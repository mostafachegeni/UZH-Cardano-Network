#!/usr/bin/env bash

set -euo pipefail

cd $CNODE_HOME
mkdir -p output

SEND_ADDR=$2
FAUCET_AMOUNT=$1
PAYMENT_KEY_PREFIX=$CNODE_HOME/initial-keys
CARDANO_NODE_SOCKET_PATH=$CNODE_HOME/sockets/node0.socket
export CARDANO_NODE_SOCKET_PATH

ADDR=$(cat $CNODE_HOME/initial-keys/utxo1.addr)
ADDR_AMOUNT=$(cardano-cli query utxo --address $ADDR --testnet-magic $NETWORK_MAGIC | awk '{if(NR==3) print $3}')
UTXO=$(cardano-cli query utxo --address $ADDR --testnet-magic $NETWORK_MAGIC | awk '{if(NR==3) print $1 "#" $2}')

cardano-cli transaction build \
    --tx-in $UTXO \
    --tx-out $SEND_ADDR+$FAUCET_AMOUNT \
    --change-address $ADDR \
    --testnet-magic $NETWORK_MAGIC \
    --out-file output/$SEND_ADDR.tx.txbody


cardano-cli transaction sign \
    --tx-body-file output/$SEND_ADDR.tx.txbody \
    --out-file output/$SEND_ADDR.tx.txsigned \
    --signing-key-file $CNODE_HOME/initial-keys/utxo1.skey

echo -n ":::"
cardano-cli transaction txid --tx-file output/$SEND_ADDR.tx.txsigned
echo -n ":::"

cardano-cli transaction submit --tx-file output/$SEND_ADDR.tx.txsigned --testnet-magic $NETWORK_MAGIC

rm -rf output/$SEND_ADDR.tx.txbody
mv output/$SEND_ADDR.tx.txsigned output/$SEND_ADDR.sent