#!/usr/bin/env bash

# Check the number of input arguments
if [ "$#" -ne 0 ]; then
    echo "You must run this script without any arguments: ./reset_script.sh"
    exit 1
fi


set -euo pipefail


FAUCET_ADDR=addr_test1qpr7re7v528ctujqdsehkvz4kre8440mqsmuqvw28h4xgpkaqfxd60wc84tu7nvqlwqvm6j3e3kewmkethu43pryt2sscrcchz
#SEND_ADDR=$2

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
done < $TXS_PATH/balance_faucet.out 

txcnt=$(cat $TXS_PATH/balance_faucet.out | wc -l)
echo Total available ADA balance: ${total_balance}
echo Number of UTXOs: ${txcnt}


cardano-cli transaction build \
    ${tx_in} \
    --change-address $FAUCET_ADDR \
    --testnet-magic $NETWORK_MAGIC \
    --out-file $TXS_PATH/tx_reset.raw


cardano-cli transaction sign \
    --tx-body-file $TXS_PATH/tx_reset.raw \
    --out-file $TXS_PATH/tx_reset.signed \
    --signing-key-file $UTXO_KEYS_PATH/payment.skey

echo -n ":::TX_ID = "
cardano-cli transaction txid --tx-file $TXS_PATH/tx_reset.signed
echo -n ":::"

# Run the cardano-cli command and capture its output
#cardano-cli transaction submit --tx-file $TXS_PATH/tx_reset.signed --testnet-magic $NETWORK_MAGIC
output=$(cardano-cli transaction submit --tx-file "$TXS_PATH/tx_reset.signed" --testnet-magic "$NETWORK_MAGIC" 2>&1)

# Check if the output contains "Transaction successfully submitted"
if [[ $output == *"Transaction successfully submitted"* ]]; then
    echo "Transaction successfully submitted."
    # Continue with the rest of your script here
else
    echo "Transaction submission failed or did not contain the expected message."
    # You may choose to handle the failure or add error-handling code here
fi

#rm $TXS_PATH/tx_reset.raw
mv $TXS_PATH/tx_reset.raw $TXS_PATH/tx_reset.raw.sent
mv $TXS_PATH/tx_reset.signed $TXS_PATH/tx_reset.signed.sent



# Check if cnode.service is running, stop it:
if systemctl is-active --quiet cnode.service; then
    echo "Stopping cnode.service..."
    sudo systemctl stop cnode.service
    echo "cnode.service has been stopped."
else
    echo "cnode.service is not running."
fi


# Backup all generated keys:
cp -r ~/keys /tmp/keys.bkp


# List of directories to be removed
directories=(
  ~/keys
  ~/nft
  ~/tmp
  ~/txs
  ~/UZH-Cardano-Network
  /opt/cardano/cnode/*
)

# Loop through the list of directories and remove them
for dir in "${directories[@]}"; do
  if [ -e "$dir" ]; then
    if [ -d "$dir" ]; then
      rm -r "$dir"
      echo "Removed directory: $dir"
    else
      echo "Not a directory: $dir"
    fi
  else
    echo "Directory does not exist: $dir"
  fi
done



