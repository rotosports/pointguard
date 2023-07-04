#!/bin/bash

echo "prepare genesis: Run validate-genesis to ensure everything worked and that the genesis file is setup correctly"
./pointguard validate-genesis --home /ethermint

echo "starting ethermint node $ID in background ..."
./pointguard start \
--home /ethermint \
--keyring-backend test

echo "started ethermint node"
tail -f /dev/null