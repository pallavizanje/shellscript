#!/bin/bash

# === CONFIGURATION ===
DB_USER="your_pg_user"
DB_NAME="your_db_name"
API_URL="https://your.api.endpoint"
AUTH_TOKEN="Bearer your_token_here"

# === FETCH UNIQUE FEED KEYS TO PROCESS ===
feed_keys=$(psql -U "$DB_USER" -d "$DB_NAME" -At -c "SELECT DISTINCT feed_def_key FROM t_dqp_feed_row_thrshld;")

for feed_key in $feed_keys; do
  echo "Processing feed_def_key: $feed_key"

  # Step 1: Fetch window_size, thresholds and business_date
  read -r FixedLowerLimit FixedUpperLimit window_size bussiness_date <<< $(
    psql -U "$DB_USER" -d "$DB_NAME" -At -c "
      SELECT row_thrshld_lower, row_thrshld_upper, window_size, bussiness_date
      FROM t_dqp_feed_row_thrshld
      WHERE feed_def_key = '$feed_key'
      LIMIT 1;")

  weekendFileExpected="false" # hardcoded or derive dynamically

  # Step 2: Cleanup old 'db' source_type records for today
  psql -U "$DB_USER" -d "$DB_NAME" -c "
    DELETE FROM t_dqp_adaptive_threshold_log
    WHERE src_feed_def_key = '$feed_key'
      AND source_type = 'db';"

  # Step 3: Insert new records based on window size
  psql -U "$DB_USER" -d "$DB_NAME" -c "
    WITH limit_value AS (
      SELECT window_size FROM t_dqp_feed_row_thrshld WHERE feed_def_key = '$feed_key'
    )
    INSERT INTO t_dqp_adaptive_threshold_log(
      src_feed_def_key, context_id, dataset_name,
      bussiness_date, feed_name, record_count, source_type
    )
    SELECT 
      frt.feed_def_key, 'ctx1', 'dataset',
      frt.bussiness_date, 'feedName',
      COALESCE(fvm.metric_val1::BIGINT, 0), 'db'
    FROM t_dqp_feed_row_thrshld frt
    JOIN t_dqp_feed_vldn_metrics fvm
      ON frt.feed_def_key = fvm.feed_inst_key
    WHERE frt.feed_def_key = '$feed_key'
    ORDER BY fvm.bussiness_date DESC
    LIMIT (SELECT window_size FROM limit_value);"

  # Step 4: Fetch record_count for first row
  record_count=$(psql -U "$DB_USER" -d "$DB_NAME" -At -c "
    SELECT record_count FROM t_dqp_adaptive_threshold_log
    WHERE src_feed_def_key = '$feed_key' AND source_type = 'db'
    ORDER BY bussiness_date DESC LIMIT 1;")

  # Step 5: Count number of inserted records for this feed_key
  record_count_in_log=$(psql -U "$DB_USER" -d "$DB_NAME" -At -c "
    SELECT COUNT(*) FROM t_dqp_adaptive_threshold_log
    WHERE src_feed_def_key = '$feed_key' AND source_type = 'db'")

  # Step 6: Construct dynamic_log_data
  dynamic_log_json="[]"
  if [ "$record_count_in_log" -eq "$window_size" ]; then
    dynamic_data=$(psql -U "$DB_USER" -d "$DB_NAME" -At -F"," -c "
      SELECT src_feed_def_key, bussiness_date, record_count, feed_name
      FROM t_dqp_adaptive_threshold_log
      WHERE src_feed_def_key = '$feed_key' AND source_type = 'db'
      ORDER BY bussiness_date DESC
    ")

    while IFS=',' read -r def_key biz_date rec_count feed_name; do
      entry=$(jq -n \
        --arg fd "$def_key" \
        --arg bd "$biz_date" \
        --arg rc "$rec_count" \
        --arg fn "$feed_name" \
        ' {
          feed_def_key: ($fd|tonumber),
          bussiness_date: $bd,
          record_count: $rc,
          feed_name: $fn,
          iqr_lower_threshold: 0,
          iqr_upper_threshold: 0,
          zscore: 0,
          gmm_lower_threshold: 0,
          gmm_upper_threshold: 0,
          iqr_outlier: null,
          zscore_outlier: null,
          if_outlier: null,
          gmm_outlier: null,
          anomaly_percentage: 0,
          last_updated_on: now
        }')
      dynamic_log_json=$(echo "$dynamic_log_json" | jq ". + [\$entry]" --argjson entry "$entry")
    done <<< "$dynamic_data"
  fi

  # Step 7: Construct request body
  request_payload=$(jq -n \
    --arg fd "$feed_key" \
    --arg bd "$bussiness_date" \
    --arg rc "$record_count" \
    --arg fn "feedName" \
    --arg ful "$FixedUpperLimit" \
    --arg fll "$FixedLowerLimit" \
    --arg ws "$window_size" \
    --arg wfe "$weekendFileExpected" \
    --argjson dld "$dynamic_log_json" \
    '{
      feed_def_key: ($fd|tonumber),
      bussiness_date: $bd,
      record_count: $rc,
      feed_name: $fn,
      rctConfig: [{
        type: "DYNAMIC",
        FixedUpperLimit: ($ful|tonumber),
        FixedLowerLimit: ($fll|tonumber),
        dynamicWindowSize: ($ws|tonumber),
        weekendFileExpected: ($wfe|test("true"))
      }],
      dynamic_log_data: $dld
    }')

  # Step 8: Make API call
  echo "Sending API request for feed_key: $feed_key"
  response=$(curl -s -X POST "$API_URL" \
    -H "Authorization: $AUTH_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$request_payload")

  echo "API Response: $response"

  # Step 9: Parse response and insert ML results
  ml_data=$(echo "$response" | jq -c '.ml_response[]')
  for row in $ml_data; do
    fd=$(echo "$row" | jq -r '.feed_def_key')
    bd=$(echo "$row" | jq -r '.bussiness_date')
    rc=$(echo "$row" | jq -r '.record_count')
    fn=$(echo "$row" | jq -r '.feed_name')
    iqr_lt=$(echo "$row" | jq -r '.iqr_lower_threshold')
    iqr_ut=$(echo "$row" | jq -r '.iqr_upper_threshold')
    zscore=$(echo "$row" | jq -r '.zscore')
    gmm_lt=$(echo "$row" | jq -r '.gmm_lower_threshold')
    gmm_ut=$(echo "$row" | jq -r '.gmm_upper_threshold')
    iqr_out=$(echo "$row" | jq -r '.iqr_outlier')
    zscore_out=$(echo "$row" | jq -r '.zscore_outlier')
    if_out=$(echo "$row" | jq -r '.if_outlier')
    gmm_out=$(echo "$row" | jq -r '.gmm_outlier')
    anomaly=$(echo "$row" | jq -r '.anomaly_percentage')

    psql -U "$DB_USER" -d "$DB_NAME" -c "
      INSERT INTO t_dqp_adaptive_threshold_log(
        src_feed_def_key, context_id, dataset_name, bussiness_date,
        feed_name, record_count, iqr_lower_threshold, iqr_upper_threshold,
        zscore, gmm_lower_threshold, gmm_upper_threshold, iqr_outlier,
        zscore_outlier, if_outlier, gmm_outlier, anomaly_percentage,
        last_updated_on, source_type)
      VALUES (
        '$fd', 'ctx1', 'dataset', '$bd', '$fn', $rc,
        $iqr_lt, $iqr_ut, $zscore, $gmm_lt, $gmm_ut,
        '$iqr_out', '$zscore_out', '$if_out', '$gmm_out', $anomaly, now(), 'ml');"
  done

done

echo "Feed processing complete."
