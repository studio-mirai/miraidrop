#!/bin/bash

MIRAIDROP_ID=$1

get_miraidrop_type() {
    OBJECT=$(sui client object $1 --json)
    echo $OBJECT | jq -r .type | sed 's/.*<\(.*\)>/\1/'
}

MIRAIDROP_TYPE=$(get_miraidrop_type $MIRAIDROP_ID)

sui client ptb \
    --move-call $PACKAGE_ID::miraidrop::initialize "<$MIRAIDROP_TYPE>" @$MIRAIDROP_ID \
    --gas-budget 100000000 \
    --json