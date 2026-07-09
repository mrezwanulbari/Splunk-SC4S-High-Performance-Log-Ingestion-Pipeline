#!/usr/bin/env bash
# SC4S container health and throughput check.
# Run on a cron schedule (e.g. every 5 minutes) and alert on non-zero exit.

set -euo pipefail

CONTAINER_NAME="${SC4S_CONTAINER_NAME:-sc4s}"
MIN_EPS_THRESHOLD="${SC4S_MIN_EPS:-1}"   # alert if events/sec drops below this during business hours

# 1. Container running check
if ! docker ps --filter "name=${CONTAINER_NAME}" --filter "status=running" | grep -q "${CONTAINER_NAME}"; then
  echo "CRITICAL: SC4S container '${CONTAINER_NAME}' is not running"
  exit 2
fi

# 2. Container health status (if a HEALTHCHECK is defined in the image)
HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "${CONTAINER_NAME}" 2>/dev/null || echo "unknown")
if [[ "${HEALTH}" == "unhealthy" ]]; then
  echo "CRITICAL: SC4S container reports unhealthy status"
  exit 2
fi

# 3. Recent log throughput check — flags silent ingestion stalls
#    (container running but no longer actually receiving/forwarding events,
#    e.g. after an upstream network ACL change breaks the syslog path)
RECENT_LINES=$(docker logs --since 5m "${CONTAINER_NAME}" 2>&1 | grep -c "events forwarded" || true)
if [[ "${RECENT_LINES}" -lt "${MIN_EPS_THRESHOLD}" ]]; then
  echo "WARNING: Low or no forwarding activity in the last 5 minutes (${RECENT_LINES} matching log lines)"
  exit 1
fi

echo "OK: SC4S container healthy, forwarding activity normal"
exit 0
