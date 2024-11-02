# MiraiDrop

MiraiDrop is an onchain airdrop manager for Sui-based coins.

## Requirements

MiraiDrop includes a variety of Bash scripts which require the official Sui client to function.

## Usage

### Create an Airdrop

```
bash scripts/create.sh <COIN_TYPE> # e.g. "0x2::sui::SUI"
```

### Add Airdrop Recipients

```
bash scripts/addRecipients.sh <MIRAIDROP_ID> <CSV_FILE> # e.g. /Users/studio-mirai/miraidrop/airdrop.csv
```

### Deposit Funds

```
bash scripts/deposit.sh <MIRAIDROP_ID> <COIN_ID>
```

### Initialize Airdrop

```
bash scripts/initialize.sh <MIRAIDROP_ID>
```

### Execute Airdrop

```
bash scripts/execute.sh <MIRAIDROP_ID> <BATCH_SIZE>
```