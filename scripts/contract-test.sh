#!/bin/bash

KEY="mykey"
CHAINID="ethermint_9000-1"
MONIKER="localtestnet"

# stop and remove existing daemon and client data and process(es)
rm -rf ~/.ethermint*
pkill -f "ethermint*"

make build-ethermint

# if $KEY exists it should be override
"$PWD"/build/pointguard keys add $KEY --keyring-backend test --algo "eth_secp256k1"

# Set moniker and chain-id for Pointguard (Moniker can be anything, chain-id must be an integer)
"$PWD"/build/pointguard init $MONIKER --chain-id $CHAINID

# Change parameter token denominations to afury
cat $HOME/.ethermint/config/genesis.json | jq '.app_state["staking"]["params"]["bond_denom"]="stake"' > $HOME/.ethermint/config/tmp_genesis.json && mv $HOME/.ethermint/config/tmp_genesis.json $HOME/.ethermint/config/genesis.json
cat $HOME/.ethermint/config/genesis.json | jq '.app_state["crisis"]["constant_fee"]["denom"]="afury"' > $HOME/.ethermint/config/tmp_genesis.json && mv $HOME/.ethermint/config/tmp_genesis.json $HOME/.ethermint/config/genesis.json
cat $HOME/.ethermint/config/genesis.json | jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="afury"' > $HOME/.ethermint/config/tmp_genesis.json && mv $HOME/.ethermint/config/tmp_genesis.json $HOME/.ethermint/config/genesis.json
cat $HOME/.ethermint/config/genesis.json | jq '.app_state["mint"]["params"]["mint_denom"]="afury"' > $HOME/.ethermint/config/tmp_genesis.json && mv $HOME/.ethermint/config/tmp_genesis.json $HOME/.ethermint/config/genesis.json

# Allocate genesis accounts (cosmos formatted addresses)
"$PWD"/build/pointguard add-genesis-account "$("$PWD"/build/pointguard keys show "$KEY" -a --keyring-backend test)" 100000000000000000000afury,10000000000000000000stake --keyring-backend test

# Sign genesis transaction
"$PWD"/build/pointguard gentx $KEY 10000000000000000000stake --amount=100000000000000000000afury --keyring-backend test --chain-id $CHAINID

# Collect genesis tx
"$PWD"/build/pointguard collect-gentxs

# Run this to ensure everything worked and that the genesis file is setup correctly
"$PWD"/build/pointguard validate-genesis

# Start the node (remove the --pruning=nothing flag if historical queries are not needed) in background and log to file
"$PWD"/build/pointguard start --pruning=nothing --rpc.unsafe --json-rpc.address="0.0.0.0:8545" --keyring-backend test > ethermint.log 2>&1 &

# Give pointguard node enough time to launch
sleep 5

solcjs --abi "$PWD"/tests/solidity/suites/basic/contracts/Counter.sol --bin -o "$PWD"/tests/solidity/suites/basic/counter
mv "$PWD"/tests/solidity/suites/basic/counter/*.abi "$PWD"/tests/solidity/suites/basic/counter/counter_sol.abi 2> /dev/null
mv "$PWD"/tests/solidity/suites/basic/counter/*.bin "$PWD"/tests/solidity/suites/basic/counter/counter_sol.bin 2> /dev/null

# Query for the account
ACCT=$(curl --fail --silent -X POST --data '{"jsonrpc":"2.0","method":"eth_accounts","params":[],"id":1}' -H "Content-Type: application/json" http://localhost:8545 | grep -o '\0x[^"]*')
echo "$ACCT"

# Start testcases (not supported)
# curl -X POST --data '{"jsonrpc":"2.0","method":"personal_unlockAccount","params":["'$ACCT'", ""],"id":1}' -H "Content-Type: application/json" http://localhost:8545

#PRIVKEY="$("$PWD"/build/pointguard keys export $KEY)"

## need to get the private key from the account in order to check this functionality.
cd tests/solidity/suites/basic/ && go get && go run main.go $ACCT

# After tests
# kill test pointguard
echo "going to shutdown pointguard in 3 seconds..."
sleep 3
pkill -f "ethermint*"