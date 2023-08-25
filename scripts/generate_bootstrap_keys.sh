#!/usr/bin/env bash

# Check if the user provided an input
if [ "$#" -ne 1 ]; then
    echo "Usage: ./generate_pool_keys.sh <pool_name>"
    return 1
fi

POOL_NAME=$1
echo POOL_NAME: $POOL_NAME

#PAYMENT_KEY_PREFIX=~/keys/utxo-keys/payment
UTXO_KEYS_PATH=~/keys/utxo-keys
POOL_KEYS_PATH=~/keys/pool-keys
mkdir -p $UTXO_KEYS_PATH
mkdir -p $POOL_KEYS_PATH



# Make a KES key pair:
#    --> KES (key evolving signature) keys are created to secure your stake pool against hackers who might compromise your keys. 
#    --> On mainnet, you will need to regenerate the KES key every 90 days.
#cd $POOL_KEYS_PATH
cardano-cli node key-gen-KES \
    --verification-key-file $POOL_KEYS_PATH/kes.vkey \
    --signing-key-file $POOL_KEYS_PATH/kes.skey

# Make cold key:
#    --> Cold keys must be generated and stored on your air-gapped offline machine. The cold keys are the files stored in $HOME/pool-keys.
#cd $POOL_KEYS_PATH
cardano-cli node key-gen \
    --cold-verification-key-file $POOL_KEYS_PATH/node.vkey \
    --cold-signing-key-file $POOL_KEYS_PATH/node.skey \
    --operational-certificate-issue-counter $POOL_KEYS_PATH/node.counter


# Determine the number of slots per KES period from the genesis file:
#slotsPerKESPeriod=$(cat $CNODE_HOME/files/shelley-genesis.json | jq -r '.slotsPerKESPeriod')
#echo slotsPerKESPeriod: ${slotsPerKESPeriod}


# Find the kesPeriod by dividing the slot tip number by the slotsPerKESPeriod:
#slotNo=$(cardano-cli query tip --testnet-magic 2023 | jq -r '.slot')
#echo slotNo: ${slotNo}
#kesPeriod=$((${slotNo} / ${slotsPerKESPeriod}))
#echo kesPeriod: ${kesPeriod}
#startKesPeriod=${kesPeriod}
#echo startKesPeriod: ${startKesPeriod}

startKesPeriod=0
echo startKesPeriod: ${startKesPeriod}


# generate an operational certificate for your pool:
#cd $POOL_KEYS_PATH
cardano-cli node issue-op-cert \
        --kes-verification-key-file $POOL_KEYS_PATH/kes.vkey \
        --cold-signing-key-file $POOL_KEYS_PATH/node.skey \
        --operational-certificate-issue-counter $POOL_KEYS_PATH/node.counter \
        --kes-period $startKesPeriod \
        --out-file $POOL_KEYS_PATH/node.cert


# Make a VRF key pair:
#cd $POOL_KEYS_PATH
cardano-cli node key-gen-VRF \
        --verification-key-file $POOL_KEYS_PATH/vrf.vkey \
        --signing-key-file $POOL_KEYS_PATH/vrf.skey

chmod 400 $POOL_KEYS_PATH/vrf.skey

mkdir -p $CNODE_HOME/priv/pool/$POOL_NAME

cp $POOL_KEYS_PATH/kes.skey $CNODE_HOME/priv/pool/$POOL_NAME/hot.skey
cp $POOL_KEYS_PATH/vrf.skey $CNODE_HOME/priv/pool/$POOL_NAME/vrf.skey
cp $POOL_KEYS_PATH/node.cert $CNODE_HOME/priv/pool/$POOL_NAME/op.cert
sudo chmod o-rwx $CNODE_HOME/priv/pool/$POOL_NAME/vrf.skey
sudo chmod g-rwx $CNODE_HOME/priv/pool/$POOL_NAME/vrf.skey




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
echo stake.addr: $(cat $UTXO_KEYS_PATH/stake.addr)

RETURN_ADDRESS=$(cat $UTXO_KEYS_PATH/stake.addr)


