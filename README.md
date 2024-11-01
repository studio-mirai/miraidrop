# MiraiDrop

MiraiDrop is an onchain airdrop manager for Sui-based coins.

## Requirements

MiraiDrop includes a variety of Bash scripts which require the official Sui client to function.

## Usage

### Create an Airdrop

```
bash scripts/create.sh "0x2::sui::SUI"
```

### Deposit Funds

```
bash scripts/deposit.sh <MIRAIDROP_ID> <COIN_ID>
```