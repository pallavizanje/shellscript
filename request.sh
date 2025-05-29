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
  local context_id="${10}"
  local dataset_name="${11}"

  jq -n \
    --arg feed_def_key "$feed_def_key" \
    --arg bussiness_date "$bussiness_date" \
    --argjson record_count "$record_count" \
    --arg feed_name "$feed_name" \
    --argjson FixedUpperLimit "$fixed_upper" \
    --argjson FixedLowerLimit "$fixed_lower" \
    --argjson dynamicWindowSize "$window_size" \
    --arg weekendFileExpected "$weekend_expected" \
    --argjson dynamic_log_data "$dynamic_log_data" \
    --arg context_id "$context_id" \
    --arg dataset_name "$dataset_name" \
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
        feed_name: $feed_name,
        context_id: $context_id,
        dataset_name: $dataset_name
      },
      dynamic_log_data: $dynamic_log_data
    }'
}
