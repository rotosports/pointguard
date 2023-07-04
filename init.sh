#!/bin/bash
# SPDX-License-Identifier: BUSL-1.1
#
# Copyright (C) 2023, Blackchain Foundation. All rights reserved.
# Use of this software is govered by the Business Source License included
# in the LICENSE file of this repository and at www.mariadb.com/bsl11.
#
# ANY USE OF THE LICENSED WORK IN VIOLATION OF THIS LICENSE WILL AUTOMATICALLY
# TERMINATE YOUR RIGHTS UNDER THIS LICENSE FOR THE CURRENT AND ALL OTHER
# VERSIONS OF THE LICENSED WORK.
#
# THIS LICENSE DOES NOT GRANT YOU ANY RIGHT IN ANY TRADEMARK OR LOGO OF
# LICENSOR OR ITS AFFILIATES (PROVIDED THAT YOU MAY USE A TRADEMARK OR LOGO OF
# LICENSOR AS EXPRESSLY REQUIRED BY THIS LICENSE).
#
# TO THE EXTENT PERMITTED BY APPLICABLE LAW, THE LICENSED WORK IS PROVIDED ON
# AN “AS IS” BASIS. LICENSOR HEREBY DISCLAIMS ALL WARRANTIES AND CONDITIONS,
# EXPRESS OR IMPLIED, INCLUDING (WITHOUT LIMITATION) WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT, AND
# TITLE.


DEVS1="dev0"
DEVS2="dev1"
CHAINID="highbury_710-1"
MONIKER="the-watchers"
# Remember to change to other types of keyring like 'file' in-case exposing to outside world,
# otherwise your balance will be wiped quickly
# The keyring test does not require private key to steal tokens from you
KEYRING="test"
LOGLEVEL="info"
# Set dedicated home directory for the pointguard instance
HOMEDIR="$HOME/.pointguard"
# to trace evm
#TRACE="--trace"
TRACE=""

# Path variables
CONFIG_TOML=$HOMEDIR/config/config.toml
APP_TOML=$HOMEDIR/config/app.toml
GENESIS=$HOMEDIR/config/genesis.json
TMP_GENESIS=$HOMEDIR/config/tmp_genesis.json

# used to exit on first error (any non-zero exit code)
set -e

# Reinstall daemon
make build

# # User prompt if an existing local node configuration is found.
# if [ -d "$HOMEDIR" ]; then
# 	printf "\nAn existing folder at '%s' was found. You can choose to delete this folder and start a new local node with new keys from genesis. When declined, the existing local node is started. \n" "$HOMEDIR"
# 	echo "Overwrite the existing configuration and start a new local node? [y/n]"
# 	read -r overwrite
# else
overwrite="Y"
# fi


# Setup local node if overwrite is set to Yes, otherwise skip setup
if [[ $overwrite == "y" || $overwrite == "Y" ]]; then
	# Remove the previous folder
	rm -rf "$HOMEDIR"

    	# Set moniker and chain-id (Moniker can be anything, chain-id must be an integer)
	pointguard init $MONIKER -o --chain-id $CHAINID --home "$HOMEDIR"

	# Set client config
	pointguard config keyring-backend $KEYRING --home "$HOMEDIR"
	pointguard config chain-id "$CHAINID" --home "$HOMEDIR"

	# If keys exist they should be deleted
	pointguard keys add $DEVS1 --keyring-backend test 
	pointguard keys add $DEVS2 --keyring-backend test 

	# Change parameter token denominations to axfury
	jq '.app_state["staking"]["params"]["bond_denom"]="axfury"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
	jq '.app_state["crisis"]["constant_fee"]["denom"]="axfury"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
	jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="axfury"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
	jq '.app_state["mint"]["params"]["mint_denom"]="axfury"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"
	jq '.consensus["params"]["block"]["max_gas"]="30000000"' "$GENESIS" >"$TMP_GENESIS" && mv "$TMP_GENESIS" "$GENESIS"

	# Allocate genesis accounts (cosmos formatted addresses)
	pointguard add-genesis-account $DEVS1 1000000000000000000000000avfury --keyring-backend $KEYRING --home "$HOMEDIR"
	pointguard add-genesis-account $DEVS2 1000000000000000000000000avfury --keyring-backend $KEYRING --home "$HOMEDIR"

	# Sign genesis transaction
	pointguard gentx $DEVS1 10000000000000000000avfury --keyring-backend $KEYRING --chain-id $CHAINID --home "$HOMEDIR"
	## In case you want to create multiple validators at genesis
	## 1. Back to `pointguard keys add` step, init more keys
	## 2. Back to `pointguard add-genesis-account` step, add balance for those
	## 3. Clone this ~/.pointguard home directory into some others, let's say `~/.clonedfury`
	## 4. Run `gentx` in each of those folders
	## 5. Copy the `gentx-*` folders under `~/.clonedfury/config/gentx/` folders into the original `~/.pointguard/config/gentx`

	# Collect genesis tx
	pointguard collect-gentxs --home "$HOMEDIR"

	# Run this to ensure everything worked and that the genesis file is setup correctly
	pointguard validate-genesis --home "$HOMEDIR"

	if [[ $1 == "pending" ]]; then
		echo "pending mode is on, please wait for the first block committed"
	fi
fi

# Start the node (remove the --pruning=nothing flag if historical queries are not needed)m
# pointguard start --pruning=nothing "$TRACE" --log_level $LOGLEVEL --api.enabled-unsafe-cors --api.enable --api.swagger --minimum-gas-prices=0.0001avfury --home "$HOMEDIR"