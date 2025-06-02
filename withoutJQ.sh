echo "$response" | sed -n '/"output": \[/,/\]/{//!p}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -d '\n' | \
sed 's/},{/}|{/g' | tr '|' '\n' | while read -r row; do

  row=$(echo "$row" | sed -e 's/^[[:space:]]*{//' -e 's/}[[:space:]]*$//')

  # Helper to extract field from JSON-like string
  get_value() {
    echo "$row" | grep -o "\"$1\":[^,}]*" | cut -d':' -f2- | sed 's/^ *"//;s/"$//'
  }

  feed_def_key=$(get_value "feed_def_key")
  bussiness_date=$(get_value "bussinessDate")
  feed_name=$(get_value "feed_name")
  record_count=$(get_value "recordCount")
  iqr_lower=$(get_value "iqrLowerThreshold")
  iqr_upper=$(get_value "iqrUpperThreshold")
  zscore=$(get_value "zscore")
  gmm_lower=$(get_value "gmmLowerThreshold")
  gmm_upper=$(get_value "gmmUpperThreshold")
  iqr_outlier=$(get_value "iqrOutlier")
  zscore_outlier=$(get_value "zscore_outlier")
  if_outlier=$(get_value "ifOutlier")
  gmm_outlier=$(get_value "gmmOutlier")
  anomaly_percentage=$(get_value "anomalyPercentage")

  # Defaults for null/missing values
  record_count=${record_count:-0}
  iqr_lower=${iqr_lower:-0}
  iqr_upper=${iqr_upper:-0}
  zscore=${zscore:-0}
  gmm_lower=${gmm_lower:-0}
  gmm_upper=${gmm_upper:-0}
  anomaly_percentage=${anomaly_percentage:-0}

  log "Inserting ML response for feed_def_key=$feed_def_key..."

  psql "$DB_CONN" <<SQL
INSERT INTO t_dqp_adaptive_threshold_log (
  src_feed_def_key, bussiness_date, feed_name, record_count,
  iqr_lower_threshold, iqr_upper_threshold, zscore,
  gmm_lower_threshold, gmm_upper_threshold,
  iqr_outlier, zscore_outlier, if_outlier, gmm_outlier,
  anomaly_percentage, last_updated_on, source_type
) VALUES (
  '$feed_def_key', '$bussiness_date', '$feed_name', '$record_count',
  $iqr_lower, $iqr_upper, $zscore,
  $gmm_lower, $gmm_upper,
  '$iqr_outlier', '$zscore_outlier', '$if_outlier', '$gmm_outlier',
  $anomaly_percentage, now(), 'ML'
);
SQL

  log "Inserted ML data for $feed_def_key."

done
