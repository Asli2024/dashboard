#!/usr/bin/env bash
# Usage: ./test-alarms.sh <environment> <region>
# Example: ./test-alarms.sh prod eu-west-1
#
# What this does:
#   1. Checks each alarm exists and shows its current state
#   2. Forces each alarm into ALARM state so you can verify
#      SNS notifications, PagerDuty, etc. fire correctly
#   3. Resets each alarm back to OK

set -euo pipefail

ENV="${1:?Usage: $0 <environment> <region>}"
REGION="${2:?Usage: $0 <environment> <region>}"

ALARMS=(
  "${ENV}-lambda-errors"
  "${ENV}-lambda-throttles"
  "${ENV}-lambda-duration"
  "${ENV}-lambda-concurrency"
  "${ENV}-apigw-5xx"
  "${ENV}-apigw-4xx"
  "${ENV}-apigw-latency"
  "${ENV}-apigw-count-low"
  "${ENV}-ec2-cpu"
  "${ENV}-ec2-status-check"
  "${ENV}-ec2-network-in"
  "${ENV}-ec2-disk-read-ops"
)

# Amplify alarms use app IDs not env prefix — list them separately
# by querying CloudWatch for alarms whose name starts with "amplify-"
AMPLIFY_ALARMS=$(aws cloudwatch describe-alarms \
  --region "$REGION" \
  --alarm-name-prefix "amplify-" \
  --query "MetricAlarms[].AlarmName" \
  --output text 2>/dev/null || echo "")

ALL_ALARMS=("${ALARMS[@]}")
if [[ -n "$AMPLIFY_ALARMS" ]]; then
  # shellcheck disable=SC2207
  ALL_ALARMS+=( $(echo "$AMPLIFY_ALARMS") )
fi

# -------------------------------------------------------
# Step 1: Check all alarms exist and print current state
# -------------------------------------------------------
echo ""
echo "=== Current alarm states ==="
for alarm in "${ALL_ALARMS[@]}"; do
  state=$(aws cloudwatch describe-alarms \
    --region "$REGION" \
    --alarm-names "$alarm" \
    --query "MetricAlarms[0].StateValue" \
    --output text 2>/dev/null || echo "NOT FOUND")
  printf "  %-50s %s\n" "$alarm" "$state"
done

# -------------------------------------------------------
# Step 2: Force each alarm into ALARM state
# -------------------------------------------------------
echo ""
echo "=== Forcing alarms into ALARM state ==="
for alarm in "${ALL_ALARMS[@]}"; do
  result=$(aws cloudwatch describe-alarms \
    --region "$REGION" \
    --alarm-names "$alarm" \
    --query "MetricAlarms[0].AlarmName" \
    --output text 2>/dev/null || echo "None")

  if [[ "$result" == "None" || -z "$result" ]]; then
    echo "  SKIP (not found): $alarm"
    continue
  fi

  aws cloudwatch set-alarm-state \
    --region "$REGION" \
    --alarm-name "$alarm" \
    --state-value ALARM \
    --state-reason "Manual test from test-alarms.sh"

  echo "  ALARM: $alarm"
done

echo ""
echo "Alarms set to ALARM. Check your SNS/PagerDuty notifications now."
echo "Press Enter to reset all alarms back to OK, or Ctrl+C to leave them in ALARM..."
read -r

# -------------------------------------------------------
# Step 3: Reset all alarms back to OK
# -------------------------------------------------------
echo ""
echo "=== Resetting alarms to OK ==="
for alarm in "${ALL_ALARMS[@]}"; do
  result=$(aws cloudwatch describe-alarms \
    --region "$REGION" \
    --alarm-names "$alarm" \
    --query "MetricAlarms[0].AlarmName" \
    --output text 2>/dev/null || echo "None")

  if [[ "$result" == "None" || -z "$result" ]]; then
    continue
  fi

  aws cloudwatch set-alarm-state \
    --region "$REGION" \
    --alarm-name "$alarm" \
    --state-value OK \
    --state-reason "Manual reset from test-alarms.sh"

  echo "  OK: $alarm"
done

echo ""
echo "Done. All alarms reset to OK."
