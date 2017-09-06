
## Gamble Dapp

### Test

Tests are included and can be run on using [truffle](https://github.com/trufflesuite/truffle) and [testrpc](https://github.com/ethereumjs/testrpc).

    brew install npm
    npm install -g truffle
    npm install -g ethereumjs-testrpc

#### Prerequisites

    node v8.1.3+
    npm v5.3.0+
    truffle v3.4.5+
    testrpc v4.0.1+

##### Testrpc

Test in the development period.

To run the test, execute the following commands from the project's root folder.

    npm start
    npm test


##### Dev

Test in real private network

To migrate the contracts to the network, execute the following commands from the project's truffle folder.

    geth --dev --rpc  --rpcport 8545 --rpcaddr 127.0.0.1 --rpcapi="eth,net,web3" --unlock 2e1609032a6e71eac236c6487c4dc3e0aaee3c9f --mine --minerthreads=1
    truffle migrate --network dev
