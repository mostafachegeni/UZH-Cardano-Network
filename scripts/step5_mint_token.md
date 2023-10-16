# Minting NFTs in the UZH-Cardano-Network

This guide provides a step-by-step walkthrough on minting non-fungible tokens (NFTs) within our private Cardano network, known as [UZH-Cardano-Network](https://github.com/mostafachegeni/UZH-Cardano-Network).

### Understanding Native Tokens and Assets

Cardano's Blockchain uniquely enables users to create, manage, and delete custom tokens or 'assets' natively. Here, 'native' implies that besides transacting in Cardano's official currency, ada, users can seamlessly interact with custom assets without relying on smart contracts. While these native assets bear similarities to ada, they also have distinct attributes:

- **Amount/Value**: Specifies the total available.
- **Name**: Descriptive label.
- **Unique PolicyID**: Since asset names aren't unique and can be replicated, each Cardano NFT is distinguished by a unique policyID. This ID arises from a policy script which outlines attributes like the entities allowed to mint tokens and the timeframes for these operations.

Technically, NFTs mirror native assets. However, for a native asset to be considered an NFT, it must be 'non-fungible', indicating that it should possess unique identifiers or traits. Typically, this means the token's quantity is one.

### Time-Locked Constraints for NFTs

Considering the potential trade and sale of NFTs, they must adhere to stringent policies. Often, an asset's value is gauged by its artificial scarcity, which can be controlled using multi-signature scripts. In this guide, we'll implement these constraints:

1. Only a specified signature can mint or burn the NFT.
2. This signature remains valid for 10,000 slots, offering flexibility should any issue arise.

### Our NFT's Reference Image

Our NFT will link to an image `ipfs://QmbqYorMg8xsiUGnmU9dXfHZCvq8kXZYrcUxvScdG5stKV` stored on the InterPlanetary File System (IPFS), a decentralized peer-to-peer network for data storage and sharing.
To view the image, access it through the [pinata gateway](https://gateway.pinata.cloud/ipfs/QmbqYorMg8xsiUGnmU9dXfHZCvq8kXZYrcUxvScdG5stKV).

# 1. Initiating the Process

Start by running a Cardano node and connecting to the UZH-Cardano network. For a comprehensive guide on setting up a Cardano node in the UZH-Cardano network, refer to our [UZH Gitlab repository](https://gitlab.uzh.ch/mostafa.chegenizadeh/uzh-cardano-network) or our [GitHub repository](https://github.com/mostafachegeni/UZH-Cardano-Network).

# 2. Set up a new working directory
It is crucial to organize our files efficiently. Let's begin by creating a new working directory named nft. This will serve as our workspace for all tasks related to this module. Upon executing these commands, you'll have established 'nft' as your current working directory, ensuring all our subsequent activities are neatly contained within this folder. Follow the commands below:
```
cd ~
mkdir -p nft
cd nft/
```


# 3. Structuring Important Values
It is essential to make our workflow as seamless as possible. We'll set vital values in variables that are easily readable, ensuring clarity and efficiency throughout our exercise. Notably, the token name should be represented in hexadecimal format. Upon execution, you've assigned the necessary values, including the token name in its hexadecimal representation, ready for the subsequent steps in our process. Follow the commands below:
```
realtokenname="NFT1"
tokenname=$(echo -n $realtokenname | xxd -b -ps -c 80 | tr -d '\n')
tokenamount="1"
ipfs_hash="QmbqYorMg8xsiUGnmU9dXfHZCvq8kXZYrcUxvScdG5stKV"
```


# 4. Generating Payment Keys and Payment Address
The next pivotal step involves generating the necessary keys and addresses. These are the foundational elements that will enable our token transactions:
```
# Generate the keys
cardano-cli address key-gen --verification-key-file payment.vkey --signing-key-file payment.skey

# Build the address
cardano-cli address build --payment-verification-key-file payment.vkey --out-file payment.addr --testnet-magic 2023
address=$(cat payment.addr)
```

# 5. Receiving Funds
```
# Display your payment address
cat payment.addr
```

```
# ------------------------------------------------------------------------------------------------
# This command MUST be executed on the bootstrap node to send 20 ADA to the address you've just generated:
        ~/UZH-Cardano-Network/scripts/send_ada.sh 20000000 <ADDRESS>
# ------------------------------------------------------------------------------------------------
```
Ensure you replace `<ADDRESS>` with the payment address you previously displayed.


To check if the address has successfully received the funds, use the following command:
```
cardano-cli query utxo --address $address --testnet-magic 2023
# The output should look like the following:
#                            TxHash                                 TxIx        Amount
# --------------------------------------------------------------------------------------
# 739b67b424ed75a69d4e1b2756c12ac2f49c26e6dbf23ce446343379cf861e2b     0        20000000 lovelace + TxOutDatumNone
```


# 6. Exporting Protocol Parameters
To ensure we are all aligned with the network's current configuration, we'll now export the protocol parameters. This step ensures that we work with the most recent network settings:
```
cardano-cli query protocol-parameters --testnet-magic 2023 --out-file protocol.json
```
By executing the above command, you'll have saved the protocol parameters to a file named protocol.json, which will be referenced in our subsequent steps.


# 7. Generating Policy Keys for Token Operations
Within the Cardano network, each token operation is guided by a specific policy that outlines its behavior and rules. This policy is backed by cryptographic keys which serve as a unique identifier and a measure of security. In this step, we'll be generating a pair of policy keys. These keys play a dual role:
  1. They form an integral component of the policy script, which sets the guidelines for the token.
  2. They are used for signing the minting transaction, ensuring authenticity and integrity.
Here's how we can create these keys:
```
# set up a dedicated directory for policy-related files
mkdir -p policy

# generate the policy keys
cardano-cli address key-gen \
  --verification-key-file policy/policy.vkey \
  --signing-key-file policy/policy.skey
```



# 8. Defining Script File for Token Operations
The backbone of our token operations lies in a script that defines the rules and boundaries for our assets. This script ensures that our tokens function within the constraints we've outlined for them. Let's delve into creating a script that:
  1. Allows only one signature for minting.
  2. Prevents any further minting or burning of the asset after 10,000 slots have lapsed post-transaction.

To begin, determine the `current slot number + 10000`, which serves as our baseline:
```
slotnumber=$(expr $(cardano-cli query tip --testnet-magic 2023 | jq .slot?) + 10000)
```

Now, it's time to structure our policy.script file that incorporates these characteristics:
```
echo "{" > policy/policy.script
echo "  \"type\": \"all\"," >> policy/policy.script
echo "  \"scripts\":" >> policy/policy.script
echo "  [" >> policy/policy.script
echo "   {" >> policy/policy.script
echo "     \"type\": \"before\"," >> policy/policy.script
echo "     \"slot\": $slotnumber" >> policy/policy.script
echo "   }," >> policy/policy.script
echo "   {" >> policy/policy.script
echo "     \"type\": \"sig\"," >> policy/policy.script
echo "     \"keyHash\": \"$(cardano-cli address key-hash --payment-verification-key-file policy/policy.vkey)\"" >> policy/policy.script
echo "   }" >> policy/policy.script
echo "  ]" >> policy/policy.script
echo "}" >> policy/policy.script
```


To verify our script's integrity and ensure it matches our desired characteristics, let's display its content:
```
cat policy/policy.script
# The output should look like the following:
#{
#  "type": "all",
#  "scripts":
#  [
#   {
#     "type": "before",
#     "slot": 2523661
#   },
#   {
#     "type": "sig",
#     "keyHash": "66f967dbb85e864f5eb8ac3997eaa2c4ae7891c2ef264e9e5def3f66"
#   }
#  ]
#}
```


Lastly, allocate the script to a variable for easy referencing in our upcoming steps:
```
script="policy/policy.script"
```



# 9. Deriving the PolicyID from the Policy Script
In the Cardano ecosystem, each token's behavior and rules are dictated by its associated policy. A unique identifier, known as the policyID, is used to represent this policy throughout the network. This policyID is not arbitrarily assigned; instead, it's derived by computing the hash of the policy script.

To generate the policyID, follow these commands:
```
# Compute the hash of our policy script to produce the policyID
cardano-cli transaction policyid --script-file ./policy/policy.script > policy/policyID

# Assign the generated policyID to a variable for easier reference in subsequent steps
policyid=$(cat policy/policyID)

# Display the derived policyID to verify its generation
cat policy/policyID
```




# 10. Defining Metadata for our NFT
Metadata plays a critical role in the Cardano ecosystem as it carries vital information about the tokens. Essentially, it's a set of data that describes and gives information about other data. In the context of our token operations, we'll adjust our metadata to encompass pivotal details that would be stored on the blockchain. Notably, this metadata will house the `policyID`, which serves as a unique identifier for our token's governing rules, and the address of our NFT image on the InterPlanetary File System (IPFS).

To structure our metadata, use the following commands:
```
echo "{" > metadata.json
echo "  \"721\": {" >> metadata.json
echo "    \"$(cat policy/policyID)\": {" >> metadata.json
echo "      \"$(echo $realtokenname)\": {" >> metadata.json
echo "        \"description\": \"A sample NFT on UZH-Cardano Network\"," >> metadata.json
echo "        \"name\": \"UZH-Cardano NFT\"," >> metadata.json
echo "        \"id\": \"1\"," >> metadata.json
echo "        \"image\": \"ipfs://$(echo $ipfs_hash)\"" >> metadata.json
echo "      }" >> metadata.json
echo "    }" >> metadata.json
echo "  }" >> metadata.json
echo "}" >> metadata.json
```

To ensure everything is in place and looks as expected, display the content of our metadata:
```
cat metadata.json
# The output should look like the following:
#{
#  "721": {
#    "b98f50c644394116ae302d70ede70d2e15a19ddc4411e3a41eab32a4": {
#      "NFT1": {
#        "description": "A sample NFT on UZH-Cardano Network",
#        "name": "UZH-Cardano NFT",
#        "id": "1",
#        "image": "ipfs://QmRhTTbUrPYEw3mJGGhQqQST9k86v1DPBiTTWJGKDJsVFw"
#      }
#    }
#  }
#}
```


# 11. Build and Submit NFT Transaction to Cardano Blockchain
The minting of an NFT on the Cardano network involves a series of intricate steps, from building the transaction to ultimately submitting it to the blockchain. Let's break down this process.

## 11.1. Discovering UTXOs (Unspent Transaction Outputs)
Before constructing our transaction, we need to determine the current balance and UTXOs associated with our address. UTXOs are vital components of the Cardano transaction model, representing assets that are yet to be spent.
```
output=3000000
NETWORK_MAGIC=2023
TXS_PATH=./txs
mkdir -p $TXS_PATH
cardano-cli query utxo --address $(cat payment.addr) --testnet-magic $NETWORK_MAGIC > $TXS_PATH/fullUtxo.out
tail -n +3 $TXS_PATH/fullUtxo.out | sort -k3 -nr > $TXS_PATH/balance.out
cat $TXS_PATH/balance.out
tx_in=""
total_balance=0
while read -r utxo; do
in_addr=$(awk '{ print $1 }' <<< "${utxo}")
idx=$(awk '{ print $2 }' <<< "${utxo}")
utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
total_balance=$((${total_balance}+${utxo_balance}))
echo TxHash: ${in_addr}#${idx}
echo ADA: ${utxo_balance}
tx_in="${tx_in} --tx-in ${in_addr}#${idx}"
done < $TXS_PATH/balance.out
```
This command will identify and collate all UTXOs related to our address, paving the way for the transaction's construction.


## 11.2. Building the Transaction
Here, we structure the transaction, incorporating details such as the token amount, policy ID, token name, policy script, and our predefined metadata.
```
cardano-cli transaction build \
        --testnet-magic 2023 \
        ${tx_in} \
        --tx-out $address+$output+"$tokenamount $policyid.$tokenname" \
        --change-address $address \
        --mint="$tokenamount $policyid.$tokenname" \
        --minting-script-file $script \
        --metadata-json-file metadata.json  \
        --invalid-hereafter $slotnumber \
        --witness-override 2 \
        --out-file $TXS_PATH/matx.raw
```


## 11.3. Signing the Transaction
For security reasons and to validate authenticity, transactions on the Cardano network need to be signed using secret keys associated with the involved assets and addresses.
```
cardano-cli transaction sign  \
        --signing-key-file payment.skey  \
        --signing-key-file policy/policy.skey  \
        --testnet-magic 2023 \
        --tx-body-file $TXS_PATH/matx.raw  \
        --out-file $TXS_PATH/matx.signed
```


## 11.4. Submitting the Transaction
With our signed transaction in hand, the next step is to broadcast it to the Cardano network, allowing it to be validated and recorded on the blockchain.
```
cardano-cli transaction submit --tx-file $TXS_PATH/matx.signed --testnet-magic 2023
```

# 12. Verification
To ensure our NFT has been successfully minted and is now linked to our address, we can check the list of all UTXOs associated with our address.
```
cardano-cli query utxo --address $address --testnet-magic 2023
# The output should look like the following:
#                            TxHash                                 TxIx        Amount
# --------------------------------------------------------------------------------------
# 739b67b424ed75a69d4e1b2756c12ac2f49c26e6dbf23ce446343379cf861e2b     0        3000000 lovelace + 1 e70b796ee73d1e6c70e2e0425cf2e2a6b9893ba1cf6cd5318a2b5524.4e465431 + TxOutDatumNone
# 739b67b424ed75a69d4e1b2756c12ac2f49c26e6dbf23ce446343379cf861e2b     1        16433669 lovelace + TxOutDatumNone 
```

Upon completion of these steps, your unique NFT will have been successfully minted and recorded on the Cardano blockchain, a testament to the network's versatility and robustness.
