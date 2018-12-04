#!/usr/bin/env sh

DOMAIN="$1"

echo "Counting workflow and activity types in $DOMAIN domain..."

REGISTERED_ACTIVITY_TYPES=$(aws swf list-activity-types --domain $DOMAIN --registration-status REGISTERED | jq '.typeInfos | length')
DEPRECATED_ACTIVITY_TYPES=$(aws swf list-activity-types --domain $DOMAIN --registration-status DEPRECATED | jq '.typeInfos | length')

echo "\nACTIVITIES:"
echo "Registered: $REGISTERED_ACTIVITY_TYPES"
echo "Deprecated: $DEPRECATED_ACTIVITY_TYPES"

TOTAL=$((REGISTERED_ACTIVITY_TYPES + DEPRECATED_ACTIVITY_TYPES))
echo "Total: $TOTAL"

REGISTERED_WORKFLOW_TYPES=$(aws swf list-workflow-types --domain $DOMAIN --registration-status REGISTERED | jq '.typeInfos | length')
DEPRECATED_WORKFLOW_TYPES=$(aws swf list-workflow-types --domain $DOMAIN --registration-status DEPRECATED | jq '.typeInfos | length')

echo "\nWORKFLOWS:"
echo "Registered: $REGISTERED_WORKFLOW_TYPES"
echo "Deprecated: $DEPRECATED_WORKFLOW_TYPES"

TOTAL=$((REGISTERED_WORKFLOW_TYPES + DEPRECATED_WORKFLOW_TYPES))
echo "Total: $TOTAL"

TOTAL=$((REGISTERED_ACTIVITY_TYPES + DEPRECATED_ACTIVITY_TYPES + REGISTERED_WORKFLOW_TYPES + DEPRECATED_WORKFLOW_TYPES))
echo "\nTOTAL: $TOTAL"
