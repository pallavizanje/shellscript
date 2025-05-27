log "Sending API request for $feed_def_key..."
response=$(curl -s -X POST "$API_URL" -H "Content-Type: application/json" -d @"$TMP_FILE")
log "API response received."

# Extract status from response
status=$(echo "$response" | jq -r '.status')

if [[ "$status" == "pass" ]]; then
  log "✅ API response status is 'pass'. Proceeding to insert records..."

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
  done

else
  log "❌ API response status is '$status'. Skipping insert."
fi
