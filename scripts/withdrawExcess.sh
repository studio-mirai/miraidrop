#!/bin/bash

# Validate command line arguments
if [ $# -ne 1 ]; then
    echo "Error: Required exactly 1 argument" >&2
    echo "Usage: $0 <miraidrop_id>" >&2
    exit 1
fi

get_miraidrop_type() {
    OBJECT=$(sui client object $1 --json)
    echo $OBJECT | jq -r .type | sed 's/.*<\(.*\)>/\1/'
}

MIRAIDROP_ID=$1

MIRAIDROP_TYPE=$(get_miraidrop_type $MIRAIDROP_ID)

sui client ptb \
    --move-call $MIRAIDROP_PACKAGE_ID::miraidrop::withdraw_excess "<$MIRAIDROP_TYPE>" @$MIRAIDROP_ID \
    --assign coin \
    --transfer-objects [coin] @$(sui client active-address) \
    --gas-budget 100000000 \
    --json