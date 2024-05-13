#!/usr/bin/env bash

# Check if the user provided an input
if [ "$#" -ne 1 ]; then
    echo "Usage: ./step2_initiate_node.sh <pool_name>"
    return 1
fi



SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

NETWORK_MAGIC=2023
TMP_PATH=~/tmp


mkdir -p "$TMP_PATH"
curl -sS -o "$TMP_PATH/guild-deploy.sh" https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/guild-deploy.sh
chmod 755 "$TMP_PATH/guild-deploy.sh"

# Download the latest pre-built "binaries" available which will be stored in the ~/.local/bin directory:
"$TMP_PATH/guild-deploy.sh" -s d


# Define the export line you want to add, for example:
EXPORT_LINE='export CARDANO_NODE_SOCKET_PATH="${CNODE_HOME}/sockets/node.socket"'
if ! grep -qF "$EXPORT_LINE" ~/.bashrc; then
    # If the line does not exist, append it
    echo "$EXPORT_LINE" >> ~/.bashrc
fi


source ~/.bashrc


# Check if CNODE_HOME is set
if [ -z "$CNODE_HOME" ]; then
    echo "Error: CNODE_HOME environment variable is not set!"
    return 1
fi

# Copy the genesis files of our UZH-Cardano network:
rm "$CNODE_HOME/files"/*
cp "$SCRIPT_DIR/../files"/* "$CNODE_HOME/files/"

# Update "topology file" to be able to connect to the "Relay Node (172.23.57.67)" and "Bootstrap Node (172.23.57.68)" and "Backup Main Producer (172.23.57.69)":
cat > "$CNODE_HOME/files"/topology.json << EOF
{"Producers": [
    {
      "addr": "130.60.144.50",
      "port": 6000,
      "valency": 1
    },
    {
      "addr": "130.60.144.49",
      "port": 6000,
      "valency": 1
    },
    {
      "addr": "172.23.57.69",
      "port": 6000,
      "valency": 1
    },
    {
      "addr": "172.23.57.67",
      "port": 6000,
      "valency": 1
    }
]}
EOF



# Check if the cnode env file exists
CNODE_ENV_FILE="$CNODE_HOME/scripts/env"
if [ ! -f "$CNODE_ENV_FILE" ]; then
    echo "Error: File $CNODE_ENV_FILE does not exist!"
    return 1
fi

# Use awk to find and insert the line to the env file:
PATTERN="POOL_NAME"
NEW_LINE="POOL_NAME=\"$1\""
awk -v pattern="$PATTERN" -v newline="$NEW_LINE" '
$0 ~ pattern && !modif { print $0; print newline; modif=1; next }
{ print }
' "$CNODE_ENV_FILE" > "${CNODE_ENV_FILE}.tmp" && mv "${CNODE_ENV_FILE}.tmp" "$CNODE_ENV_FILE"

