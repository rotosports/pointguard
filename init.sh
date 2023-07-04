#!/bin/bash

KEY="mykey"
CHAINID="opti_9000-1"
MONIKER="localtestnet"
KEYRING="test"
KEYALGO="eth_secp256k1"
LOGLEVEL="info"
# to trace evm
TRACE="--trace"
# TRACE=""
DIR="${HOME_DIR:-/.pointguardd}"
GENESIS_FILE="${DIR}/config/genesis.json"

# validate dependencies are installed
command -v jq > /dev/null 2>&1 || { echo >&2 "jq not installed. More info: https://stedolan.github.io/jq/download/"; exit 1; }

# Only generate a new genesis.json file if there isn't an existing one
if [[ ! -f "$GENESIS_FILE" ]]; then

  # remove existing daemon and client
  rm -rf ~/.pointguardd*

  pointguardd config keyring-backend $KEYRING
  pointguardd config chain-id $CHAINID

  # if $KEY exists it should be deleted
  pointguardd keys add $KEY --keyring-backend $KEYRING --algo $KEYALGO

  # Set moniker and chain-id for Pointguard (Moniker can be anything, chain-id must be an integer)
  pointguardd init $MONIKER --chain-id $CHAINID

  # Change parameter token denominations to afury
  cat $HOME/.pointguardd/config/genesis.json | jq '.app_state["staking"]["params"]["bond_denom"]="afury"' > $HOME/.pointguardd/config/tmp_genesis.json && mv $HOME/.pointguardd/config/tmp_genesis.json $HOME/.pointguardd/config/genesis.json
  cat $HOME/.pointguardd/config/genesis.json | jq '.app_state["crisis"]["constant_fee"]["denom"]="afury"' > $HOME/.pointguardd/config/tmp_genesis.json && mv $HOME/.pointguardd/config/tmp_genesis.json $HOME/.pointguardd/config/genesis.json
  cat $HOME/.pointguardd/config/genesis.json | jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="afury"' > $HOME/.pointguardd/config/tmp_genesis.json && mv $HOME/.pointguardd/config/tmp_genesis.json $HOME/.pointguardd/config/genesis.json
  cat $HOME/.pointguardd/config/genesis.json | jq '.app_state["mint"]["params"]["mint_denom"]="afury"' > $HOME/.pointguardd/config/tmp_genesis.json && mv $HOME/.pointguardd/config/tmp_genesis.json $HOME/.pointguardd/config/genesis.json

  # increase block time (?)
  cat $HOME/.pointguardd/config/genesis.json | jq '.consensus_params["block"]["time_iota_ms"]="1000"' > $HOME/.pointguardd/config/tmp_genesis.json && mv $HOME/.pointguardd/config/tmp_genesis.json $HOME/.pointguardd/config/genesis.json

  # Set gas limit in genesis
  cat $HOME/.pointguardd/config/genesis.json | jq '.consensus_params["block"]["max_gas"]="10000000"' > $HOME/.pointguardd/config/tmp_genesis.json && mv $HOME/.pointguardd/config/tmp_genesis.json $HOME/.pointguardd/config/genesis.json

  # disable produce empty block
  if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' 's/create_empty_blocks = true/create_empty_blocks = false/g' $HOME/.pointguardd/config/config.toml
    else
      sed -i 's/create_empty_blocks = true/create_empty_blocks = false/g' $HOME/.pointguardd/config/config.toml
  fi

  if [[ $1 == "pending" ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/g' $HOME/.pointguardd/config/config.toml
        sed -i '' 's/timeout_propose = "3s"/timeout_propose = "30s"/g' $HOME/.pointguardd/config/config.toml
        sed -i '' 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' $HOME/.pointguardd/config/config.toml
        sed -i '' 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' $HOME/.pointguardd/config/config.toml
        sed -i '' 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' $HOME/.pointguardd/config/config.toml
        sed -i '' 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' $HOME/.pointguardd/config/config.toml
        sed -i '' 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' $HOME/.pointguardd/config/config.toml
        sed -i '' 's/timeout_commit = "5s"/timeout_commit = "150s"/g' $HOME/.pointguardd/config/config.toml
        sed -i '' 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' $HOME/.pointguardd/config/config.toml
    else
        sed -i 's/create_empty_blocks_interval = "0s"/create_empty_blocks_interval = "30s"/g' $HOME/.pointguardd/config/config.toml
        sed -i 's/timeout_propose = "3s"/timeout_propose = "30s"/g' $HOME/.pointguardd/config/config.toml
        sed -i 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' $HOME/.pointguardd/config/config.toml
        sed -i 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' $HOME/.pointguardd/config/config.toml
        sed -i 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' $HOME/.pointguardd/config/config.toml
        sed -i 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' $HOME/.pointguardd/config/config.toml
        sed -i 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' $HOME/.pointguardd/config/config.toml
        sed -i 's/timeout_commit = "5s"/timeout_commit = "150s"/g' $HOME/.pointguardd/config/config.toml
        sed -i 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' $HOME/.pointguardd/config/config.toml
    fi
  fi

  # Allocate genesis accounts (cosmos formatted addresses)
  pointguardd add-genesis-account $KEY 100000000000000000000000000afury --keyring-backend $KEYRING

  # Sign genesis transaction
  pointguardd gentx $KEY 1000000000000000000000afury --keyring-backend $KEYRING --chain-id $CHAINID

  # Collect genesis tx
  pointguardd collect-gentxs

  # Run this to ensure everything worked and that the genesis file is setup correctly
  pointguardd validate-genesis
else
  # We already have a genesis.json file so create an empty priv_validator_state.json
  mkdir $DIR/data
  cat >> $DIR/data/priv_validator_state.json << EOF
  {
    "height": "0",
    "round": 0,
    "step": 0
  }
EOF

# Run this to ensure everything the genesis file is setup correctly
pointguardd validate-genesis $GENESIS_FILE

fi