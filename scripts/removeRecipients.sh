#!/bin/bash

MIRAIDROP_ID=$1
BATCH_SIZE=$2

get_miraidrop_type() {
    OBJECT=$(sui client object $1 --json)
    echo $OBJECT | jq -r .type | sed 's/.*<\(.*\)>/\1/'
}

MIRAIDROP_TYPE=$(get_miraidrop_type $MIRAIDROP_ID)

sui client ptb \
    --move-call $MIRAIDROP_PACKAGE_ID::miraidrop::remove_recipients "<$MIRAIDROP_TYPE>" @$MIRAIDROP_ID @$BATCH_SIZE \
    --gas-budget 100000000 \
    --json