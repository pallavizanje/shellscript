#!/bin/bash

# ---------- CONFIG ----------
DB_CONN="postgres://username:password@localhost:5432/dbname"
API_URL="http://your-api-url.com/endpoint"
TMP_FILE="/tmp/request_payload.json"
LOG_FILE="/tmp/adaptive_threshold_log.txt"

# ---------- LOGGING ----------
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# ---------- PAYLOAD BUILDER ----------
build_request_payload() {
  local feed_def_key="$1"
  local bussiness_date="$2"
  local record_count="$3"
  local feed_name="$4"
  local fixed_upper="$5"
  local fixed_lower="$6"
  local window_size="$7"
  local weekend_expected="$8"
  local dynamic_log_data="$9"

  cat <<EOF
{
  "feed_def_key": "$feed_def_key",
  "bussiness_date": "$bussiness_date",
  "record_count": "$record_count",
  "feed_name": "$feed_name",
  "rctConfig": [
    {
      "type": "DYNAMIC",
      "FixedUpperLimit": $fixed_upper,
      "FixedLowerLimit": $fixed_lower,
      "dynamicWindowSize": $window_size,
      "weekendFileExpected": "$weekend_expected"
    }
  ],
  "dynamic_log_data": $dynamic_log_data
}
EOF
}

# ---------- MAIN FUNCTION ----------
dynamic_count() {
  local feed_def_key="$1"
  local bussiness_date="$2"
  local record_count="$3"
  local feed_name="$4"
  local fixed_upper="$5"
  local fixed_lower="$6"
  local window_size="$7"
  local weekend_expected="$8"

  log "Starting dynamic_count for feed_def_key=$feed_def_key"

  log_count=$(psql "$DB_CONN" -t -c "
    SELECT COUNT(*) FROM t_dqp_adaptive_threshold_log
    WHERE src_feed_def_key = '$feed_def_key'
      AND source_type = 'db';
  " | xargs)

  if [[ "$log_count" -eq 0 ]]; then
    log "No existing DB records for $feed_def_key — inserting initial data..."

    psql "$DB_CONN" <<SQL
INSERT INTO t_dqp_adaptive_threshold_log (
  src_feed_def_key,
  context_id,
  dataset_name,
  bussiness_date,
  feed_name,
  record_count,
  source_type
)
SELECT
  frt.feed_def_key,
  '1',
  'dataset',
  frt.bussiness_date,
  '$feed_name',
  CAST(COALESCE(fvm.metric_val1, '0') AS BIGINT),
  'db'
FROM t_dqp_feed_row_thrshld frt
JOIN t_dqp_feed_vldn_metrics fvm
  ON frt.feed_def_key = fvm.feed_inst_key
WHERE frt.feed_def_key = '$feed_def_key'
ORDER BY frt.bussiness_date DESC
LIMIT $window_size;
SQL

    log "Initial records inserted for feed_def_key=$feed_def_key"

    # Re-fetch log count after insert
    log_count=$(psql "$DB_CONN" -t -c "
      SELECT COUNT(*) FROM t_dqp_adaptive_threshold_log
      WHERE src_feed_def_key = '$feed_def_key'
        AND source_type = 'db';
    " | xargs)
  else
    log "DB records already exist for feed_def_key=$feed_def_key"
  fi

  if [[ "$log_count" -eq "$window_size" ]]; then
    log "Condition 1 matched: log count = window size. Preparing dynamic_log_data..."

    dynamic_log_data=$(psql "$DB_CONN" -t -A -F ',' -c "
      SELECT json_build_object(
        'feed_def_key', src_feed_def_key,
        'bussiness_date', bussiness_date,
        'record_count', record_count,
        'feed_name', feed_name,
        'iqr_lower_threshold', iqr_lower_threshold,
        'iqr_upper_threshold', iqr_upper_threshold,
        'zscore', zscore,
        'gmm_lower_threshold', gmm_lower_threshold,
        'gmm_upper_threshold', gmm_upper_threshold,
        'iqr_outlier', iqr_outlier,
        'zscore_outlier', zscore_outlier,
        'if_outlier', if_outlier,
        'gmm_outlier', gmm_outlier,
        'anomaly_percentage', anomaly_percentage,
        'last_updated_on', last_updated_on
      )
      FROM t_dqp_adaptive_threshold_log
      WHERE src_feed_def_key = '$feed_def_key'
        AND source_type = 'db'
    " | jq -s '.')

  else
    log "Condition 2 matched: log count != window size. Using empty dynamic_log_data..."
    dynamic_log_data="[]"
  fi

  request_body=$(build_request_payload "$feed_def_key" "$bussiness_date" "$record_count" "$feed_name" "$fixed_upper" "$fixed_lower" "$window_size" "$weekend_expected" "$dynamic_log_data")
  echo "$request_body" > "$TMP_FILE"

  log "Sending API request for $feed_def_key..."
  response=$(curl -s -X POST "$API_URL" -H "Content-Type: application/json" -d @"$TMP_FILE")
  log "API response received."

  echo "$response" | jq -c '.ml_response[]' | while read -r row; do
    log "Inserting ML response for feed_def_key=$feed_def_key..."

    feed_def_key=$(echo "$row" | jq -r '.feed_def_key')
    bussiness_date=$(echo "$row" | jq -r '.bussiness_date')
    feed_name=$(echo "$row" | jq -r '.feed_name')
    record_count=$(echo "$row" | jq -r '.record_count')
    iqr_lower=$(echo "$row" | jq -r '.iqr_lower_threshold')
    iqr_upper=$(echo "$row" | jq -r '.iqr_upper_threshold')
    zscore=$(echo "$row" | jq -r '.zscore')
    gmm_lower=$(echo "$row" | jq -r '.gmm_lower_threshold')
    gmm_upper=$(echo "$row" | jq -r '.gmm_upper_threshold')
    iqr_outlier=$(echo "$row" | jq -r '.iqr_outlier')
    zscore_outlier=$(echo "$row" | jq -r '.zscore_outlier')
    if_outlier=$(echo "$row" | jq -r '.if_outlier')
    gmm_outlier=$(echo "$row" | jq -r '.gmm_outlier')
    anomaly_percentage=$(echo "$row" | jq -r '.anomaly_percentage')

    psql "$DB_CONN" <<SQL
INSERT INTO t_dqp_adaptive_threshold_log (
  src_feed_def_key, bussiness_date, feed_name, record_count,
  iqr_lower_threshold, iqr_upper_threshold, zscore,
  gmm_lower_threshold, gmm_upper_threshold,
  iqr_outlier, zscore_outlier, if_outlier, gmm_outlier,
  anomaly_percentage, last_updated_on, source_type
) VALUES (
  '$feed_def_key', '$bussiness_date', '$feed_name', $record_count,
  $iqr_lower, $iqr_upper, $zscore,
  $gmm_lower, $gmm_upper,
  '$iqr_outlier', '$zscore_outlier', '$if_outlier', '$gmm_outlier',
  $anomaly_percentage, now(), 'ML'
);
SQL

    log "Inserted ML data for $feed_def_key."
  done

  log "Completed dynamic_count for feed_def_key=$feed_def_key"
}

# ---------- EXAMPLE CALL ----------
# Uncomment and replace values for manual testing
# dynamic_count "feed_key_123" "2024-05-20" "100" "my_feed" "200" "50" "5" "YES"
