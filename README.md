# UZH-Cardano Network

Welcome to this hands-on guide, tailored to provide you with a comprehensive walkthrough on establishing and managing a Cardano node. 
Our journey will commence with the initial setup of a Cardano node, which will serve as the foundation of our operations. 
Following this, we will delve into the intricate process of key generation, transforming our node into a block-producing entity, also known as a stake pool. 
As we progress, we will set up both payment and stake keys essential for our pool's operations. 
Registration is pivotal; thus, we will guide you through the steps to register both the stake address and the stake pool, ensuring your node is recognized within our UZH-Cardano network. 
Once set up, we will demonstrate how to confirm your pool's functionality and ensure it is operating seamlessly. 
Last but not least, we will conclude by walking you through the procedure to withdraw the hard-earned rewards from your stake address, 
transferring them safely to your payment address, and de-registering the stake pool and stake address.

 
**IMPORTANT NOTE: Throughout the hands-on exercise, it is imperative that you maintain all records of the outputs generated in your terminal after executing the following scripts: `step6_register_stake_address.sh`, `step7_register_stake_pool.sh`, `step9_withdraw_rewards.sh`, `step10_deregister_pool.sh`, and `step11_deregister_stake_address.sh`. Subsequently, please forward these output records to the Teaching Assistants (TAs) upon completion of the exercise as a pdf file.
This action is not simply a procedural requirement; it holds significant importance for two critical reasons:
Firstly, providing the TAs with the complete output records allows them to thoroughly assess and verify your successful execution of the hands-on session, ensuring you receive the proper credit and feedback.
Secondly, it plays a crucial role in maintaining the integrity and continuity of our learning resources for future sessions. By retaining these records, we ensure that all funds utilized during the exercise are correctly returned to the faucet, safeguarding the availability of resources for upcoming learners.**




## 1. Clone Repository:
When setting up the `"UZH-Cardano-Network"` repository, begin by executing `git clone https://github.com/mostafachegeni/UZH-Cardano-Network`. 
This command downloads the repository to your local machine, creating a directory named "UZH-Cardano-Network". 
After cloning, navigate into this new directory using `cd UZH-Cardano-Network`. 
Once inside, you will want to ensure that all the shell script files (ending in .sh) within the `"scripts"` directory are executable. 
To achieve this, use the `chmod +x scripts/*.sh` command, which grants execute permissions to these script files. 
By following these steps, you will have the repository set up and scripts ready for execution on your local machine.

```bash
[]% cd ~
[]% git clone https://github.com/mostafachegeni/UZH-Cardano-Network
[]% cd UZH-Cardano-Network
[]% chmod +x scripts/*.sh
```



## 2. Run a Cardano node:


In this guide, we will be using a series of commands to manage and monitor our Cardano node. 
Starting off, `source ./scripts/step2_initiate_node.sh "pool2"` initializes our node, specifically naming it `"pool2"`. 
To ensure our environment variables are loaded properly, we will use `source ~/.bashrc`. 
Moving forward, we will deploy our Cardano node as a systemd service using the `"$CNODE_HOME/scripts/cnode.sh" -d` command. 

```bash
[]% source ./scripts/step2_initiate_node.sh "pool2"

[]% source ~/.bashrc

# Deploy a Cardano node as a systemd service:
[]% "$CNODE_HOME/scripts/cnode.sh" -d
# The output should look like this:
#        Deploying cnode as systemd service..
#        cnode.service deployed successfully!!
#        Created symlink /etc/systemd/system/multi-user.target.wants/cnode.service → /etc/systemd/system/cnode.service.


# Start the service:
[]% sudo systemctl start cnode.service
```


Once deployed, monitoring becomes vital; `sudo systemctl status cnode.service` provides an overview of the service's current status, 
while `journalctl -u cnode -f` lets us inspect its startup attempts in real-time. 
Lastly, for those keen on observing blockchain activity, `cardano-cli query tip --testnet-magic 2023` reveals the latest point, or "tip", of the blockchain, 
and `$CNODE_HOME/scripts/gLiveView.sh` offers an interactive view of our node's operations within the network.

```bash
# Check status of the service:
# To return to the terminal, press Ctrl+c.
[]% sudo systemctl status cnode.service

# Check startup attempts for the cnode service:
# To return to the terminal, press Ctrl+c.
[]% journalctl -u cnode -f

# Check the tip of the blockchain:
[]% cardano-cli query tip --testnet-magic 2023
[]% $CNODE_HOME/scripts/gLiveView.sh
```



It is imperative to ensure that your node is fully synchronized with the network before proceeding with subsequent operations. 
To confirm this, please wait until the "syncProgress" indicator reaches "100.00". 
You can periodically monitor the synchronization progress of your node by executing the `cardano-cli query tip --testnet-magic 2023` command. 
Only when "syncProgress" displays "100.00" can you be certain that your node is in complete harmony with the network.



## 3. Generate Keys for the Block-Producing Node:

Proceeding to the next pivotal step in our node setup: the generation of keys for our block-producing node. 
Initiate this process using `source ./scripts/step3_generate_pool_keys.sh "pool2"`. 
Once the keys are generated, it is crucial to restart the node service for the changes to take effect; 
achieve this by employing the `sudo systemctl restart cnode.service` command. 
Continuous monitoring ensures the stability of our operations. 
Utilize `sudo systemctl status cnode.service` for a quick health check and `journalctl -u cnode -f` for a detailed, real-time view. 
Further, confirm your node's sync status using `cardano-cli query tip --testnet-magic 2023`. 
To cap off this step, ensure a new "BLOCK PRODUCTION" section is visible in the panel by running `$CNODE_HOME/scripts/gLiveView.sh`. 
This indicates the successful transition of your node into a block-producing entity.




```bash
[]% cd ~/UZH-Cardano-Network

[]% source ./scripts/step3_generate_pool_keys.sh "pool2"
# The output should look like this:
#        POOL_NAME: pool2
#        slotsPerKESPeriod: 129600
#        slotNo: 831023
#        kesPeriod: 6
#        startKesPeriod: 6


# Restart the cnode service:
[]% sudo systemctl restart cnode.service

# Monitor the service:
# To return to the terminal, press Ctrl+c.
[]% sudo systemctl status cnode.service
[]% journalctl -u cnode -f

# Check the tip of the blockchain. You can also check the node's synchronization percentage to the blockchain:
[]% cardano-cli query tip --testnet-magic 2023

# Make sure that a "BLOCK PRODUCTION" section is added to the panel. This will appear after you are 100.0% synchronized to the blockchain.
[]% $CNODE_HOME/scripts/gLiveView.sh
```



## 4. Setting Up Payment and Stake Keys:

The subsequent stage in our Cardano node journey is the establishment of both payment and stake keys. 
These keys are paramount, allowing us to engage in financial transactions and stake operations within the network. 
Begin this setup by executing `source ./scripts/step4_setup_payment_stake_keys.sh "pool2"`. 
Once established, you can swiftly identify your unique payment address using `cat ~/keys/utxo-keys/payment.addr`. 
This address is what you will provide to the TAs. Post submission, you might be curious about your ADA balance. 
To get an insight, simply run `cardano-cli query utxo --address $(cat ~/keys/utxo-keys/payment.addr) --testnet-magic 2023`. 
Once you receive a balance, it is a confirmation that you have been credited with ADA in your payment address.


**IMPORTANT NOTE: It is crucial for participants to note that once you have successfully generated your payment address, you must promptly send this address to the _Teaching Assistants (TAs)_ through the following form: [UZH-Cardano Payment Address](https://forms.office.com/e/s4hdXGtih5). 
By doing so, the TAs will ensure that funds (in the form of ADA) are transferred to your respective addresses. 
This step is imperative, as having ADA in your payment address will be essential for the upcoming operations in the hands-on session.**


```bash
[]% source ./scripts/step4_setup_payment_stake_keys.sh "pool2"
# The output should look like this:
#        POOL_NAME: pool2
#        payment.addr: addr_test1qpzy2duvgrqg6wx3xjmsaqq7s2fwsl3f08lwu6qq70750j3a82297wuzdtl42t06tsylqn2peny5mt6n2p22msjek5zskk2xz8
#        ----------------------


# Find your payment address:
[]% cat ~/keys/utxo-keys/payment.addr


# Check your balance
[]% cardano-cli query utxo --address $(cat ~/keys/utxo-keys/payment.addr) --testnet-magic 2023
# The output should look like this:
#                               TxHash                                 TxIx        Amount
#    --------------------------------------------------------------------------------------
#    ee5235df0f649c44cca5fbe445eb8b71f165a301e1da39d764d3ccd310b67513     0        2000000000000000 lovelace + TxOutDatumNone
```




## 5. Mint Native Tokens:
Please follow the instructions outlined in the [Mint Native Tokens (GitHub)](https://github.com/mostafachegeni/UZH-Cardano-Network/blob/main/scripts/step5_mint_token.md) or [Mint Native Tokens (GitLab)](https://gitlab.uzh.ch/mostafa.chegenizadeh/UZH-Cardano-Network/-/blob/main/scripts/step5_mint_token.md) for guidance.


## 6. Register Your Stake Address:

The ensuing pivotal phase involves registering your stake address. In the realm of Cardano, the pledge represents the stake you allocate to your own pool, 
symbolizing commitment and trustworthiness. To make this pledge meaningful, you must register your stake address on the blockchain. 
This specific address should be linked with a payment address that already contains funds, marking the amount you intend to pledge. 
To achieve this registration seamlessly, utilize the `source ./scripts/step6_register_stake_address.sh "pool2"` command, 
ensuring the stake address for `"pool2"` is recognized and verified on the blockchain.
The provided script is designed to generate a certificate named `stake.cert`. This certificate is meticulously crafted utilizing the `stake.vkey`. 
In essence, this process ensures that your stake key is formally recognized and can be utilized in subsequent blockchain operations.


**NOTE: To prepare your report, you should keep a record of what is printed by `step6_register_stake_address.sh`.**

```bash
[]% cd ~/UZH-Cardano-Network/
[]% source ./scripts/step6_register_stake_address.sh "pool2"
# The output should look like this:
#        POOL_NAME: pool2
#        **TxHash: fb974a0164c402e0999b74d517fbd7fd037b3a5dd08d989e18aadfa53f753518#0**
#        ADA: 1000000000000000
#        Total available ADA balance: 1000000000000000
#        Number of UTXOs: 1
#        stakeAddressDeposit : 2000000
#        Current Slot: 832157
#        fee: 179229
#        Change Output: 999999997820771
#        Transaction successfully submitted.
```


## 7. Register Your Stake Pool:

Diving into the next step, we will focus on registering your stake pool. By executing the command `source ./scripts/step7_register_stake_pool.sh "pool2"`, 
the script will generate a "registration certificate" for your stake pool and simultaneously pledge stake to it. 
This intricate operation establishes a delegation certificate. 
This certificate plays a pivotal role as it "delegates" funds from all stake addresses associated with the `stake.vkey` to the pool governed by the `cold key node.vkey`. 
It is essential to grasp some nuances here:
- **Pledge**: This represents a stake pool owner's commitment, or promise, to back their own pool financially.
- **Balance vs. Pledge**: For the pledge to be meaningful, your balance should always exceed the specified pledge amount.
- **Pledge Dynamics**: Contrary to some misconceptions, pledged funds are static; they aren't transferred or moved. For our guide's context, the pledge remains tied to the stake pool owner’s keys, specifically within `payment.addr`.
- **Implications of Not Fulfilling the Pledge**: Failure to maintain the pledged amount can have consequences. The stake pool might miss out on block minting opportunities, which in turn would mean potential rewards missed for your delegators.
- **Pledge Flexibility**: While it serves as a commitment, your pledge is not rigidly locked. Stake pool owners retain the freedom to transfer or utilize their funds as they see fit.



**NOTE: To prepare your report, you should keep a record of what is printed by `step7_register_stake_pool.sh`.**

```bash
[]% source ./scripts/step7_register_stake_pool.sh "pool2"
# The output should look like this:
#        POOL_NAME: pool2
#        minPoolCost: 340000000
#        Current Slot: 833110
#        **TxHash: 2cbdfeb32b47a2cf16993c53521914eb28bd17681790e7f2ad6005dc8454e337#0**
#        ADA: 999999997820771
#        Total available ADA balance: 1099999997820771
#        Number of UTXOs: 2
#        stakePoolDeposit: 500000000
#        fee: 196917
#        txOut: 1099999497623854
#        Transaction successfully submitted.
#        ------------------------------------------
#        possible error:
#            Command failed: transaction submit  Error: Error while submitting tx: ShelleyTxValidationError ShelleyBasedEraBabbage 
#            (ApplyTxError [UtxowFailure (UtxoFailure (AlonzoInBabbageUtxoPredFailure (ValueNotConservedUTxO (MaryValue 0 (MultiAsset (fromList []))) 
#            (MaryValue 500000000000000 (MultiAsset (fromList [])))))),UtxowFailure (UtxoFailure (AlonzoInBabbageUtxoPredFailure (BadInputsUTxO 
#            (fromList [TxIn (TxId {unTxId = SafeHash "4c63b4286007e17f517a156c70538ce068f417e4190d15e710f317437c8d60ef"}) (TxIx 0)]))))])
#
#        Solution:
#            Wait a few seconds after registering your stake address and then re-run the script.
#        ------------------------------------------
```




## 8. Verify the Stake Pool Operation:

Moving forward, a crucial phase in your journey is the verification of your stake pool's operation to ensure it is effectively integrated into the Cardano network. 
Start by computing your stake pool ID using the command `cardano-cli stake-pool id --cold-verification-key-file node.vkey`. 
With this unique ID in hand, you can then delve deeper to ascertain your pool's registration status on the blockchain. 
Execute `cardano-cli query stake-snapshot --stake-pool-id $(cardano-cli stake-pool id --cold-verification-key-file node.vkey) --testnet-magic 2023`. 
If this command yields a non-empty string, rejoice! This indicates that your stake pool is successfully registered and operational on the network.


```bash
# Your stake pool ID can be computed with:
[]% POOL_KEYS_PATH=~/keys/pool-keys; cardano-cli stake-pool id --cold-verification-key-file $POOL_KEYS_PATH/node.vkey


# Use the stake pool ID to verify it is included in the blockchain:
[]% POOL_KEYS_PATH=~/keys/pool-keys; cardano-cli query stake-snapshot --stake-pool-id $(cardano-cli stake-pool id --cold-verification-key-file $POOL_KEYS_PATH/node.vkey) --testnet-magic 2023  
# The output should look like this (After 3 epochs i.e., ~1.5 hour):
#        {
#            "pools": {
#                "249b04caca6a6c092f630ace0588ac63110cc6fa816e19991cbddcd7": {
#                    "stakeGo": 2000000497627550,
#                    "stakeMark": 2000000497627550,
#                    "stakeSet": 2000000497627550
#                }
#            },
#            "total": {
#                "stakeGo": 15125978906643434,
#                "stakeMark": 15126959282924645,
#                "stakeSet": 15126521312269178
#            }
#        }


# Find the slots in which this node will be the leader:
[]% POOL_KEYS_PATH=~/keys/pool-keys; cardano-cli query leadership-schedule --testnet-magic 2023 --genesis $CNODE_HOME/files/shelley-genesis.json --stake-pool-id $(cardano-cli stake-pool id --cold-verification-key-file $POOL_KEYS_PATH/node.vkey) --vrf-signing-key-file $POOL_KEYS_PATH/vrf.skey --current
# The output should look like this:
#             SlotNo                          UTC Time              
#        -------------------------------------------------------------
#             14078                   2023-08-28 21:30:41 UTC
#             14131                   2023-08-28 21:31:34 UTC
#             14198                   2023-08-28 21:32:41 UTC
#
#        ------------------------------------------
#        possible error:
#            Command failed: query leadership-schedule  Error: The stake pool: "8e488eb0bed88a1864531f357df7b056745b9380ac36d6bb49e4af3e" has no stake
#
#        Solution:
#            Wait two epochs (~ 1 hour) after registering your stake pool and then re-run the command.
#        ------------------------------------------
```



## 9. Withdraw Rewards:


Our subsequent step revolves around the rewarding process of withdrawing rewards. 
It is important to understand that the rewards system operates on an all-or-nothing principle; you are required to withdraw 
the entire amount of accumulated rewards in one transaction, as partial withdrawals are not permitted. 
To initiate this, start by checking the current balance of your rewards address using the command: `cardano-cli query stake-address-info --testnet-magic 2023 --address stake.addr`.
Following this, ascertain the balance of your payment address—the destination for your rewards and also the entity bearing transaction fees—by 
running: `cardano-cli query utxo --testnet-magic 2023 --address payment.addr`. 
With the necessary groundwork laid, you can then execute the `source ./scripts/step9_withdraw_rewards.sh "pool2"` command to seamlessly transfer the rewards 
from the stake (rewards) address straight to the payment address.


**NOTE: To prepare your report, you should keep a record of what is printed by `step9_withdraw_rewards.sh`.**

```bash
# Check the current balance of the rewards address:
[]% UTXO_KEYS_PATH=~/keys/utxo-keys; cardano-cli query stake-address-info --testnet-magic 2023 --address $(cat $UTXO_KEYS_PATH/stake.addr)
# The output should look like this (after 4 epochs i.e., ~2 hours):
#        [
#            {
#                "address": "stake_test1uzehfqwhq8yr8fh3rcnqwnvezq23aah2qd8xsjsatca3p2c662rjw",
#                "delegation": "pool1cma78n4mc8h577nwlnar3q9kzr04r9hze4rmcydnlvlcx599fdl",
#                "rewardAccountBalance": 2325651922856
#            }
#        ]


# Query the payment address balance (You will withdraw rewards into your payment address payment.addr):
[]% UTXO_KEYS_PATH=~/keys/utxo-keys; cardano-cli query utxo --testnet-magic 2023 --address $(cat $UTXO_KEYS_PATH/payment.addr)
# The output should look like this:
#                                   TxHash                                 TxIx        Amount
#        --------------------------------------------------------------------------------------
#        1adfa1221cfb98d6801bd9481a26b815ea4ce8d09b69e9bc876048bca43ecb19     0        999999497627198 lovelace + TxOutDatumNone


# Withdraw rewards from the stake (rewards) address to your payment address:
[]% source ./scripts/step9_withdraw_rewards.sh "pool2"
# The output should look like this:
#        POOL_NAME: pool2
#        stakePoolRewards: 10104492373247
#        Current Slot: 1265766
#        12c6ab8a2cd292f48da28d462cddd8d4eff545319180add1a01911d96af04641     0        1099998996150334 lovelace + TxOutDatumNone
#        **TxHash: 12c6ab8a2cd292f48da28d462cddd8d4eff545319180add1a01911d96af04641#0**
#        ADA: 1099998996150334
#        Total available ADA balance: 1099998996150334
#        Number of UTXOs: 1
#        fee: 185785
#        txOut: 1110103488337796
#        Transaction successfully submitted.
```




## 10. De-Register the Stake Pool:

Transitioning to the next phase, there are times when it becomes necessary to de-register a stake pool, ending its official operation on the Cardano network. 
This step ensures a clean exit, allowing for resources to be repurposed or the pool to be retired altogether. 
To execute this de-registration, you will employ the command `source ./scripts/step10_deregister_pool.sh "pool2"`. 
Once triggered, this script will handle all the intricate details, ensuring `"pool2"` is gracefully removed from the list of active stake pools on the Cardano blockchain.


**NOTE: To prepare your report, you should keep a record of what is printed by `step10_deregister_pool.sh`.**

```bash
[]% source ./scripts/step10_deregister_pool.sh "pool2"
# The output should look like this:
#        POOL_NAME: pool6
#        current epoch: 632
#        poolRetireMaxEpoch: 18
#        earliest epoch for retirement is: 633
#        latest epoch for retirement is: 650
#        **TxHash: 27b81109c1abf8d8b965c7347857d411c344a6eb9fec11e5bdd20f8a31eae10b#0**
#        ADA: 1110103488337796
#        Total available ADA balance: 1110103488337796
#        Number of UTXOs: 1
#        Current Slot: 1265880
#        fee: 179625
#        txOut: 1110103488158171
#        Transaction successfully submitted.
```



## 11. De-Register the Stake Address:

Following the de-registration of the pool, it is essential to also de-register the associated stake address. 
This step signifies the conclusion of stake-related operations for a specific address in the Cardano ecosystem. 
By executing the command `source ./scripts/step11_deregister_stake_address.sh "pool2"`, you initiate a multi-faceted process: 
first, any residual rewards are withdrawn; 
next, the stake address is de-registered; 
and finally, any remaining funds are returned to the faucet, marking the full closure of the stake address's operations.


**NOTE: To prepare your report, you should keep a record of what is printed by `step11_deregister_stake_address.sh`.**

```bash
# Withdraw rewards, de-register the stake address, and return the funds to the faucet:
[]% source ./scripts/step11_deregister_stake_address.sh "pool2"
# The output should look like this:
#        POOL_NAME: pool6
#        **TxHash: 7f868af8622d940ffcf4ba8f157889964ce1cd357c8638fa16cafd065fd9c1b7#0**
#        ADA: 1110103488158171
#        Total available ADA balance: 1110103488158171
#        Number of UTXOs: 1
#        stakePoolRewards: 0
#        Current Slot: 1265957
#        key deposit: 2000000
#        fee: 181077
#        txOut: 1110103489977094
#        Transaction successfully submitted.
#        ------------------------------------------
#        possible error:
#            Command failed: transaction submit  Error: Error while submitting tx: ShelleyTxValidationError ShelleyBasedEraBabbage (ApplyTxError [UtxowFailure (UtxoFailure (AlonzoInBabbageUtxoPredFailure
#            (ValueNotConservedUTxO (MaryValue 2000000 (MultiAsset (fromList []))) (MaryValue 220861881714956 (MultiAsset (fromList [(PolicyID {policyID = ScriptHash
#            "430a715e59527782e67ec976894e4d0f878ac9ad3d26285ec8438e0b"},fromList [("4e465431",1)])])))))),UtxowFailure (UtxoFailure (AlonzoInBabbageUtxoPredFailure (BadInputsUTxO (fromList [TxIn (TxId {unTxId = SafeHash
#            "02deae7abefb45664160ab7f35e46b99be2ccf6951b102e5875df443057f7d80"}) (TxIx 0),TxIn (TxId {unTxId = SafeHash "cfb2d0353374a336029047b7aad90ad15266e2b7a91972820cf90b2db9c6d79f"}) (TxIx 0)]))))])
#
#        Solution:
#            Wait a few seconds after de-registering your stake pool and then re-run the script.
#        ------------------------------------------


# Ensure you still have your rewards and minted NFT in your address:
[]% UTXO_KEYS_PATH=~/keys/utxo-keys; cardano-cli query utxo --testnet-magic 2023 --address $(cat $UTXO_KEYS_PATH/payment.addr)
# The output should look like this:
#                                  TxHash                                 TxIx        Amount
#        --------------------------------------------------------------------------------------
#        574ffb32b143a49f102b967c11975b871b656f5751f9ed058a704eeb6a1f5ed6     1        20861881362218 lovelace + 1 430a715e59527782e67ec976894e4d0f878ac9ad3d26285ec8438e0b.4e465431 + TxOutDatumNone
```


***

