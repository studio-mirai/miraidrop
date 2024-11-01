#!/bin/bash

get_coin_type() {
    OBJECT=$(sui client object $1 --json)
    OBJECT_TYPE=$(jq -r .type <<< "$OBJECT")

    if [[ "$OBJECT_TYPE" != "0x2::coin::Coin"* ]]; then
        echo "$COIN_ID is not a Coin object." >&2
        exit 1
    fi

    COIN_TYPE=$(sed 's/.*<//; s/>.*//' <<< "$OBJECT_TYPE")
    echo $COIN_TYPE
}

MIRAIDROP_ID=$1
COIN_ID=$2

COIN_TYPE=$(get_coin_type $COIN_ID)

sui client ptb \
    --move-call $PACKAGE_ID::miraidrop::deposit "<$COIN_TYPE>" @$MIRAIDROP_ID @$COIN_ID \
    --gas-budget 100000000 \
    --json