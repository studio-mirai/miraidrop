#!/bin/bash

MIRAIDROP_ID=$1
CSV_FILE=$2

get_miraidrop_type() {
    OBJECT=$(sui client object $1 --json)
    echo $OBJECT | jq -r .type | sed 's/.*<\(.*\)>/\1/'
}

MIRAIDROP_TYPE=$(get_miraidrop_type $MIRAIDROP_ID)

sui client ptb \
    $(while IFS=, read -r address amount; do
        echo "--move-call $PACKAGE_ID::miraidrop::add_recipient <$MIRAIDROP_TYPE> @$MIRAIDROP_ID @$address $amount"
    done < "$CSV_FILE") \
    --gas-budget 5000000000 \
    --json