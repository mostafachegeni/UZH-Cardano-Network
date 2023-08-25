#!/usr/bin/env bash

# Payment keys are used to send and receive payments and stake keys are used to manage stake delegations.


# Check if the user provided an input
if [ "$#" -ne 1 ]; then
    echo "Usage: ./step4_setup_payment_stake_keys.sh <pool_name>"
    return 1
fi

POOL_NAME=$1
echo POOL_NAME: $POOL_NAME

#PAYMENT_KEY_PREFIX=~/keys/utxo-keys/payment
UTXO_KEYS_PATH=~/keys/utxo-keys
POOL_KEYS_PATH=~/keys/pool-keys
mkdir -p $UTXO_KEYS_PATH
mkdir -p $POOL_KEYS_PATH



# Create a new "payment key pair":
#cd $UTXO_KEYS_PATH
cardano-cli address key-gen \
    --verification-key-file $UTXO_KEYS_PATH/payment.vkey \
    --signing-key-file $UTXO_KEYS_PATH/payment.skey


# Create a new "stake address key pair":
#cd $UTXO_KEYS_PATH
cardano-cli stake-address key-gen \
    --verification-key-file $UTXO_KEYS_PATH/stake.vkey \
    --signing-key-file $UTXO_KEYS_PATH/stake.skey


# Create your "stake address" from the stake address verification key:
#cd $UTXO_KEYS_PATH
cardano-cli stake-address build \
    --stake-verification-key-file $UTXO_KEYS_PATH/stake.vkey \
    --out-file $UTXO_KEYS_PATH/stake.addr \
    --testnet-magic 2023


# **************=============================================================================================================================================**************
# ************** =====>>>>>>>> Build a "payment address" for the payment key payment.vkey which will delegate to the stake address, stake.vkey <<<<<<<<===== **************:
# **************=============================================================================================================================================**************

#cd $UTXO_KEYS_PATH
cardano-cli address build \
    --payment-verification-key-file $UTXO_KEYS_PATH/payment.vkey \
    --stake-verification-key-file $UTXO_KEYS_PATH/stake.vkey \
    --out-file $UTXO_KEYS_PATH/payment.addr \
    --testnet-magic 2023



echo payment.addr: $(cat $UTXO_KEYS_PATH/payment.addr)

