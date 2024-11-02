#!/bin/bash

RESULT=$(sui client publish --skip-dependency-verification --gas-budget 1000000000 --json)

OBJECT_CHANGES=$(echo "$RESULT" | jq -r .objectChanges)

PACKAGE_ID=$(echo "$OBJECT_CHANGES" | jq -r '.[] | select(.type == "published") | .packageId')

export MIRAIDROP_PACKAGE_ID=$PACKAGE_ID
echo "MIRAIDROP_PACKAGE_ID set to: $PACKAGE_ID"