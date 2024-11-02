#!/bin/bash

MIRAIDROP_ID=$1
RECIPIENT=$2
AMOUNT=$3

get_miraidrop_type() {
    OBJECT=$(sui client object $1 --json)
    echo $OBJECT | jq -r .type | sed 's/.*<\(.*\)>/\1/'
}

MIRAIDROP_TYPE=$(get_miraidrop_type $MIRAIDROP_ID)

sui client ptb \
    --move-call $MIRAIDROP_PACKAGE_ID::miraidrop::add_recipient "<$MIRAIDROP_TYPE>" @$MIRAIDROP_ID @$RECIPIENT $AMOUNT \
    --gas-budget 100000000 \
    --json