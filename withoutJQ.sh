log "API response received. Parsing response..."

# Extract JSON array from ml_response manually
echo "$response" | grep -o '"ml_response":\[[^]]*]' | sed 's/"ml_response"://' | tr -d '\n' | \
sed 's/},{/}§{/g' | tr '§' '\n' | while read -r row; do
  # Extract individual fields
  feed_def_key=$(echo "$row" | grep -o '"feed_def_key":"[^"]*"' | cut -d':' -f2 | tr -d '"')
  business_date=$(echo "$row" | grep -o '"business_date":"[^"]*"' | cut -d':' -f2 | tr -d '"')
  feed_name=$(echo "$row" | grep -o '"feed_name":"[^"]*"' | cut -d':' -f2 | tr -d '"')
  record_count=$(echo "$row" | grep -o '"record_count":[^,}]*' | cut -d':' -f2 | tr -d '"')
  iqr_lower=$(echo "$row" | grep -o '"iqr_lower_threshold":[^,}]*' | cut -d':' -f2)
  iqr_upper=$(echo "$row" | grep -o '"iqr_upper_threshold":[^,}]*' | cut -d':' -f2)
  zscore=$(echo "$row" | grep -o '"zscore":[^,}]*' | cut -d':' -f2)
  gmm_lower=$(echo "$row" | grep -o '"gmm_lower_threshold":[^,}]*' | cut -d':' -f2)
  gmm_upper=$(echo "$row" | grep -o '"gmm_upper_threshold":[^,}]*' | cut -d':' -f2)
  iqr_outlier=$(echo "$row" | grep -o '"iqr_outlier":"[^"]*"' | cut -d':' -f2 | tr -d '"')
  zscore_outlier=$(echo "$row" | grep -o '"zscore_outlier":"[^"]*"' | cut -d':' -f2 | tr -d '"')
  if_outlier=$(echo "$row" | grep -o '"if_outlier":"[^"]*"' | cut -d':' -f2 | tr -d '"')
  gmm_outlier=$(echo "$row" | grep -o '"gmm_outlier":"[^"]*"' | cut -d':' -f2 | tr -d '"')
  anomaly_percentage=$(echo "$row" | grep -o '"anomaly_percentage":[^,}]*' | cut -d':' -f2)

  # Insert into DB
  psql "$DB_CONN" <<SQL
  INSERT INTO t_dqp_adaptive_threshold_log (
    feed_def_key, business_date, feed_name, record_count,
    iqr_lower_threshold, iqr_upper_threshold, zscore,
    gmm_lower_threshold, gmm_upper_threshold,
    iqr_outlier, zscore_outlier, if_outlier, gmm_outlier,
    anomaly_percentage, last_updated_on, source_type
  ) VALUES (
    '$feed_def_key', '$business_date', '$feed_name', '$record_count',
    $iqr_lower, $iqr_upper, $zscore,
    $gmm_lower, $gmm_upper,
    '$iqr_outlier', '$zscore_outlier', '$if_outlier', '$gmm_outlier',
    $anomaly_percentage, now(), 'ML'
  );
SQL

  log "Inserted ML response for feed_def_key=$feed_def_key"
done
