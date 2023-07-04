{
  dotenv: '../../../scripts/.env',
  'ethermint_9000-1': {
    cmd: 'pointguardd',
    'start-flags': '--trace',
    config: {
      consensus: {
        // larger timeout for more stable mempool tests
        timeout_commit: '10s',
      },
      mempool: {
        // use v1 mempool to enable tx prioritization
        version: 'v1',
      },
    },
    'app-config': {
      'minimum-gas-prices': '0afury',
      'index-events': ['ethereum_tx.ethereumTxHash'],
      'json-rpc': {
        address: '0.0.0.0:{EVMRPC_PORT}',
        'ws-address': '0.0.0.0:{EVMRPC_PORT_WS}',
        api: 'eth,net,web3,debug',
        'feehistory-cap': 100,
        'block-range-cap': 10000,
        'logs-cap': 10000,
      },
    },
    validators: [{
      coins: '1000000000000000000stake,10000000000000000000000afury',
      staked: '1000000000000000000stake',
      mnemonic: '${VALIDATOR1_MNEMONIC}',
    }, {
      coins: '1000000000000000000stake,10000000000000000000000afury',
      staked: '1000000000000000000stake',
      mnemonic: '${VALIDATOR2_MNEMONIC}',
    }],
    accounts: [{
      name: 'community',
      coins: '10000000000000000000000afury',
      mnemonic: '${COMMUNITY_MNEMONIC}',
    }, {
      name: 'signer1',
      coins: '20000000000000000000000afury',
      mnemonic: '${SIGNER1_MNEMONIC}',
    }, {
      name: 'signer2',
      coins: '30000000000000000000000afury',
      mnemonic: '${SIGNER2_MNEMONIC}',
    }],
    genesis: {
      consensus_params: {
        block: {
          max_bytes: '1048576',
          max_gas: '81500000',
        },
      },
      app_state: {
        evm: {
          params: {
            evm_denom: 'afury',
          },
        },
        gov: {
          voting_params: {
            voting_period: '10s',
          },
          deposit_params: {
            max_deposit_period: '10s',
            min_deposit: [
              {
                denom: 'afury',
                amount: '1',
              },
            ],
          },
        },
        transfer: {
          params: {
            receive_enabled: true,
            send_enabled: true,
          },
        },
        feemarket: {
          params: {
            no_base_fee: false,
            base_fee: '100000000000',
          },
        },
      },
    },
  },
}
