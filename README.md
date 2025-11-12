## Points Hook

Points Hook is a Foundry-based playground that experiments with Uniswap v4 hooks. The main contract (`src/PointsHook.sol`) mints ERC-1155 points whenever a swap routes ETH into the paired token.

### Mainnet Deployment

- Hook address: `0x6Fc3e85125171ECf8748A6ba834EA494C602c040`
- Deployment txn: `0xb57d24c3824cc397d94400fc6fea2342a847a1a2ab5cab88730faaaefe574a12`
- Deployment script: `script/DeployHook.s.sol`

### Getting Started

```shell
forge install
forge build
forge test
```

Set up the required environment variables before deploying or running scripts:

```shell
export POOL_MANAGER_ADDRESS=<pool-manager-address>
export PRIVATE_KEY=<deployer-private-key>
export MAINNET_RPC_URL=<https-endpoint>
export POOL_MANAGER_ADDRESS=0xE03A1074c86CFeDd5C142C4F04F1a1536e203543
```

### Deploying

```shell
forge script script/DeployHook.s.sol \
	--rpc-url $MAINNET_RPC_URL \
	--chain-id 1 \
	--broadcast
```

### Chain Ids

| Network           | Chain ID |
| ----------------- | -------- |
| Ethereum Mainnet  | 1        |
| Sepolia           | 11155111 |
| Avalanche         | 43114    |
| Avalanche Fuji    | 43113    |



### Tooling

- Forge for compilation, testing, and deployment (`forge --help`)
- Anvil for a local Ethereum node (`anvil`)
- Cast for chain interactions (`cast --help`)
