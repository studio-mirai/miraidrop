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

Add a single recipient like so:

```
bash scripts/addRecipients.sh <MIRAIDROP_ID> <RECIPIENT_ADDRESS> <AMOUNT>
```

Alternatively, create a CSV file that maps recipient addresses to their respective amounts, and add them in bulk like so:

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

Execute the airdrop with the specified batch size, which refers to the number of recipients to process in a single transaction. Since Sui is able to create up to 1,024 objects in a single transaction, we recommend setting the batch size to 1,000 to be safe. If your airdrop has more than 1,024 recipients, just call the function back to back until the entire list has been processed.

```
bash scripts/execute.sh <MIRAIDROP_ID> <BATCH_SIZE>
```
