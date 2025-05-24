if [[ "$log_count" -eq "$window_size" ]]; then
  log "Condition 1 matched: log count = window size. Preparing dynamic_log_data..."

  raw_psql_output=$(psql "$DB_CONN" -t -A -F ',' -c "
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
  ")

  echo "✅ Raw output from PSQL:"
  echo "$raw_psql_output"

  # Step 2: Clean and convert to JSON array
  dynamic_log_data=$(echo "$raw_psql_output" | sed '/^\s*$/d' | jq -s '.')

else
  log "Condition 2 matched: log count != window size. Using empty dynamic_log_data..."
  dynamic_log_data="[]"
fi

# Print the final dynamic_log_data
echo "✅ Parsed dynamic_log_data array:"
echo "$dynamic_log_data" | jq '.'

# Optional: Get the count
dynamic_record_count=$(echo "$dynamic_log_data" | jq 'length')
echo "📊 Number of records in dynamic_log_data: $dynamic_record_count"
