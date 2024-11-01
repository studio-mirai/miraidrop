#!/bin/bash

COIN_TYPE=$1

RESULT=$(sui client ptb \
    --move-call $PACKAGE_ID::miraidrop::new $COIN_TYPE \
    --assign result \
    --transfer-objects [result] @$(sui client active-address) \
    --gas-budget 100000000 \
    --json)

echo "MiraiDrop ID: $(echo "$RESULT" | jq -r '.events[0].parsedJson.miraidrop_id')"
echo "Type Name: $(echo "$RESULT" | jq -r '.events[0].parsedJson.type_name')"