response=$(curl -s -X POST "$API_URL" -H "Content-Type: application/json" -d @"$TEMP_FILE")

# Extract output array manually
output=$(echo "$response" | sed -n 's/.*"output":[[:space:]]*\[\(.*\)\][[:space:]]*}.*/\1/p')

if [[ -z "$output" ]]; then
  log "No output array found in response: $response"
  return
fi

# Split each object in the array
IFS='}' read -ra objects <<< "$output"
for obj in "${objects[@]}"; do
  # Clean up and re-add closing }
  obj="$obj}"
  
  # Skip if the object is too short
  [[ ${#obj} -lt 20 ]] && continue

  # Extract values using grep/sed/awk
  feed_def_key=$(echo "$obj" | grep -o '"feed_def_key":[^,}]*' | cut -d':' -f2 | tr -d '" ')
  business_date=$(echo "$obj" | grep -o '"bussinessDate":[^,}]*' | cut -d':' -f2 | tr -d '" ')
  feed_name=$(echo "$obj" | grep -o '"feed_name":[^,}]*' | head -1 | cut -d':' -f2 | tr -d '" ')
  record_count=$(echo "$obj" | grep -o '"recordCount":[^,}]*' | cut -d':' -f2 | tr -d '" ')
  iqr_lower=$(echo "$obj" | grep -o '"iqrLowerThreshold":[^,}]*' | cut -d':' -f2 | tr -d '" ')
  iqr_upper=$(echo "$obj" | grep -o '"iqrUpperThreshold":[^,}]*' | cut -d':' -f2 | tr -d '" ')
  zscore=$(echo "$obj" | grep -o '"zscore":[^,}]*' | cut -d':' -f2 | tr -d '" ')
  gmm_lower=$(echo "$obj" | grep -o '"gmmLowerThreshold":[^,}]*' | cut -d':' -f2 | tr -d '" ')
  gmm_upper=$(echo "$obj" | grep -o '"gmmUpperThreshold":[^,}]*' | cut -d':' -f2 | tr -d '" ')
  iqr_outlier=$(echo "$obj" | grep -o '"iqrOutlier":[^,}]*' | cut -d':' -f2 | tr -d '" ')
  zscore_outlier=$(echo "$obj" | grep -o '"zscore_outlier":[^,}]*' | cut -d':' -f2 | tr -d '" ')
  if_outlier=$(echo "$obj" | grep -o '"ifOutlier":[^,}]*' | cut -d':' -f2 | tr -d '" ')
  gmm_outlier=$(echo "$obj" | grep -o '"gmmOutlier":[^,}]*' | cut -d':' -f2 | tr -d '" ')
  anomaly_percentage=$(echo "$obj" | grep -o '"anomalyPercentage":[^,}]*' | cut -d':' -f2 | tr -d '" ')

  psql "$DB_CONN" <<SQL
  INSERT INTO t_dqp_adaptive_threshold_log (
    feed_def_key, business_date, feed_name, record_count,
    iqr_lower_threshold, iqr_upper_threshold, zscore,
    gmm_lower_threshold, gmm_upper_threshold,
    iqr_outlier, zscore_outlier, if_outlier, gmm_outlier,
    anomaly_percentage, last_updated_on, source_type
  ) VALUES (
    '$feed_def_key', '$business_date', '$feed_name', $record_count,
    $iqr_lower, $iqr_upper, $zscore,
    $gmm_lower, $gmm_upper,
    '$iqr_outlier', '$zscore_outlier', '$if_outlier', '$gmm_outlier',
    $anomaly_percentage, now(), 'ML'
  );
SQL

  log "Inserted ML response for feed_def_key=$feed_def_key"
done
