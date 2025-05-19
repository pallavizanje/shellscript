#!/bin/bash

# Define variables
SQL_FILE_PATH="adaptive_threshold_logic.sql"
API_URL="https://your-api-endpoint.com/analyze"
LOG_FILE="adaptive_threshold.log"

# Fetch all feed_def_keys to process
feed_def_keys=$(psql -t -A -F"," -f "$SQL_FILE_PATH" -v action="get_feed_keys")

# Loop through each feed_def_key
for feed_def_key in $feed_def_keys; do
  echo "Processing feed_def_key: $feed_def_key" | tee -a "$LOG_FILE"

  # Delete old records where source_type = 'db'
  psql -f "$SQL_FILE_PATH" -v action="delete_old" -v feed_def_key="$feed_def_key"

  # Insert latest metrics into t_dqp_adaptive_threshold_log
  psql -f "$SQL_FILE_PATH" -v action="insert_new" -v feed_def_key="$feed_def_key"

  # Get the current window size and record count in log table
  read window_size log_count <<< $(psql -t -A -F"," -f "$SQL_FILE_PATH" -v action="get_window_and_log_count" -v feed_def_key="$feed_def_key")

  # Get row threshold limits and weekendFileExpected
  read lower_limit upper_limit weekend_expected <<< $(psql -t -A -F"," -f "$SQL_FILE_PATH" -v action="get_thresholds" -v feed_def_key="$feed_def_key")

  # Get base values for requestBody
  read latest_business_date latest_record_count latest_feed_name <<< $(psql -t -A -F"," -f "$SQL_FILE_PATH" -v action="get_base_info" -v feed_def_key="$feed_def_key")

  # Build rctConfig JSON
  rctConfig=$(jq -n \
    --arg type "DYNAMIC" \
    --argjson FixedUpperLimit "$upper_limit" \
    --argjson FixedLowerLimit "$lower_limit" \
    --argjson dynamicWindowSize "$window_size" \
    --argjson weekendFileExpected "$weekend_expected" \
    '[{type: $type, FixedUpperLimit: $FixedUpperLimit, FixedLowerLimit: $FixedLowerLimit, dynamicWindowSize: $dynamicWindowSize, weekendFileExpected: $weekendFileExpected}]')

  # Generate dynamic_log_data payload based on record count
  if [ "$log_count" -lt "$window_size" ]; then
    dynamic_log_data="[]"
  else
    dynamic_log_data=$(psql -t -A -F"|" -f "$SQL_FILE_PATH" -v action="select_log_for_api" -v feed_def_key="$feed_def_key" | \
      jq -Rn '[inputs | split("|") | {
        feed_def_key: .[0]|tonumber,
        bussiness_date: .[1],
        record_count: .[2],
        feed_name: .[3],
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
      }]')
  fi

  # Construct the final request payload
  request_body=$(jq -n \
    --arg feed_def_key "$feed_def_key" \
    --arg bussiness_date "$latest_business_date" \
    --arg record_count "$latest_record_count" \
    --arg feed_name "$latest_feed_name" \
    --argjson rctConfig "$rctConfig" \
    --argjson dynamic_log_data "$dynamic_log_data" \
    '{feed_def_key: $feed_def_key, bussiness_date: $bussiness_date, record_count: $record_count, feed_name: $feed_name, rctConfig: $rctConfig, dynamic_log_data: $dynamic_log_data}')

  echo "Request: $request_body" | tee -a "$LOG_FILE"

  # Make API call
  response=$(curl -s -X POST -H "Content-Type: application/json" -d "$request_body" "$API_URL")

  echo "Response: $response" | tee -a "$LOG_FILE"

  # Insert response ml_response back into DB
  echo "$response" | jq -c '.ml_response[]' | while read -r ml_row; do
    feed_def_key=$(echo "$ml_row" | jq -r '.feed_def_key')
    bussiness_date=$(echo "$ml_row" | jq -r '.bussiness_date')
    record_count=$(echo "$ml_row" | jq -r '.record_count')
    feed_name=$(echo "$ml_row" | jq -r '.feed_name')
    iqr_lower_threshold=$(echo "$ml_row" | jq -r '.iqr_lower_threshold')
    iqr_upper_threshold=$(echo "$ml_row" | jq -r '.iqr_upper_threshold')
    zscore=$(echo "$ml_row" | jq -r '.zscore')
    gmm_lower_threshold=$(echo "$ml_row" | jq -r '.gmm_lower_threshold')
    gmm_upper_threshold=$(echo "$ml_row" | jq -r '.gmm_upper_threshold')
    iqr_outlier=$(echo "$ml_row" | jq -r '.iqr_outlier')
    zscore_outlier=$(echo "$ml_row" | jq -r '.zscore_outlier')
    if_outlier=$(echo "$ml_row" | jq -r '.if_outlier')
    gmm_outlier=$(echo "$ml_row" | jq -r '.gmm_outlier')
    anomaly_percentage=$(echo "$ml_row" | jq -r '.anomaly_percentage')

    psql -f "$SQL_FILE_PATH" \
      -v action="insert_ml_response" \
      -v src_feed_def_key="$feed_def_key" \
      -v bussiness_date="$bussiness_date" \
      -v feed_name="$feed_name" \
      -v record_count="$record_count" \
      -v iqr_lower_threshold="$iqr_lower_threshold" \
      -v iqr_upper_threshold="$iqr_upper_threshold" \
      -v zscore="$zscore" \
      -v gmm_lower_threshold="$gmm_lower_threshold" \
      -v gmm_upper_threshold="$gmm_upper_threshold" \
      -v iqr_outlier="$iqr_outlier" \
      -v zscore_outlier="$zscore_outlier" \
      -v if_outlier="$if_outlier" \
      -v gmm_outlier="$gmm_outlier" \
      -v anomaly_percentage="$anomaly_percentage"
  done

  echo "Completed processing for feed_def_key: $feed_def_key" | tee -a "$LOG_FILE"
done
