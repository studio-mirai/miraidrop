#!/bin/bash

COIN_TYPE=$1

if [ -z "$COIN_TYPE" ]; then
    echo "Error: COIN_TYPE argument is required"
    echo "Usage: $0 <COIN_TYPE>"
    exit 1
fi

RESULT=$(sui client ptb \
    --move-call $MIRAIDROP_PACKAGE_ID::miraidrop::new $COIN_TYPE \
    --assign result \
    --move-call $MIRAIDROP_PACKAGE_ID::miraidrop::transfer "<$MIRAIDROP_PACKAGE_ID::miraidrop::MiraiDrop<$COIN_TYPE>>" result @$(sui client active-address) \
    --gas-budget 100000000 \
    --json)

echo "MiraiDrop ID: $(echo "$RESULT" | jq -r '.events[0].parsedJson.miraidrop_id')"
echo "Type Name: $(echo "$RESULT" | jq -r '.events[0].parsedJson.type_name')"