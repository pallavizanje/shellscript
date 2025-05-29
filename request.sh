# ---------- CONFIG ----------
DB_CONN="postgres://username:password@localhost:5432/dbname"
API_URL="http://your-api-url.com/endpoint"
ACCESS_TOKEN="your_access_token_here"  # <-- add your token here
TMP_FILE="/tmp/request_payload.json"
LOG_FILE="/tmp/adaptive_threshold_log.txt"

# ---------- LOGGING ----------
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# ---------- PAYLOAD BUILDER ----------
build_request_payload() {
  jq -n \
    --arg feed_def_key "$1" \
    --arg bussiness_date "$2" \
    --argjson record_count "$3" \
    --arg feed_name "$4" \
    --argjson FixedUpperLimit "$5" \
    --argjson FixedLowerLimit "$6" \
    --argjson dynamicWindowSize "$7" \
    --arg weekendFileExpected "$8" \
    --argjson dynamic_log_data "$9" \
    '{
      rctConfig: {
        type: "DYNAMIC",
        FixedUpperLimit: $FixedUpperLimit,
        FixedLowerLimit: $FixedLowerLimit,
        dynamicWindowSize: $dynamicWindowSize,
        weekendFileExpected: $weekendFileExpected,
        feed_def_key: $feed_def_key,
        bussiness_date: $bussiness_date,
        record_count: $record_count,
        feed_name: $feed_name
      },
      dynamic_log_data: $dynamic_log_data
    }'
}
