#!/bin/bash

# -----------------------------
# Configuration
# -----------------------------
API_URL="https://example.com/post-api"
AUTH_TOKEN="your_auth_token"

# -----------------------------
# Step 1: Run the SQL to get data
# -----------------------------
rows=$(psql -t -A -F"|" -f select_payload.sql)

# -----------------------------
# Step 2: Parse rows & group
# -----------------------------
echo "$rows" | awk -F"|" '
{
  feed_id=$1
  feed_name=$2
  bus_date=$3
  window_size=$4
  upper_limit=$5
  lower_limit=$6
  fc_bus_date=$7
  rct_count=$8

  key=feed_id "|" feed_name "|" bus_date "|" window_size "|" upper_limit "|" lower_limit
  row_json = "{ \"bus_date\": \"" fc_bus_date "\", \"rct_count\": " rct_count ", \"zscore\": 0, \"msScore\": 0 }"

  all_rows[key] = all_rows[key] (all_rows[key] ? "," : "") row_json
  full_rows[key] = full_rows[key] "\n" feed_id "|" feed_name "|" fc_bus_date "|" upper_limit "|" lower_limit "|" rct_count "|" window_size
  count[key]++
  latest_row[key] = row_json
}
END {
  for (k in count) {
    split(k, parts, "|")
    feed_id = parts[1]
    feed_name = parts[2]
    bus_date = parts[3]
    window_size = parts[4]
    upper_limit = parts[5]
    lower_limit = parts[6]

    rcount = count[k]

    # Determine what to send to API
    config_json = "["
    if (rcount >= window_size) {
      config_json = config_json all_rows[k] "]"
    } else if (rcount > 0) {
      config_json = config_json latest_row[k] "]"
    } else {
      config_json = "[]"
    }

    payload = "{"
    payload = payload "\"feed_id\": " feed_id ","
    payload = payload "\"feed_name\": \"" feed_name "\","
    payload = payload "\"bus_date\": \"" bus_date "\","
    payload = payload "\"upper_limit\": " upper_limit ","
    payload = payload "\"lower_limit\": " lower_limit ","
    payload = payload "\"window_size\": " window_size ","
    payload = payload "\"rct_config\": " config_json
    payload = payload "}"

    print payload "<<<DELIM>>>" full_rows[k]
  }
}
' | while IFS='<<<DELIM>>>' read -r api_payload full_row_block; do

  # Step 1: Insert original records into ml_log (from DB)
  echo "$full_row_block" | while IFS="|" read -r feed_id feed_name bus_date upper_limit lower_limit rct_count window_size; do
    if [[ -n "$feed_id" ]]; then
      psql \
        --set=feed_id="$feed_id" \
        --set=feed_name="$feed_name" \
        --set=bus_date="$bus_date" \
        --set=upper_limit="$upper_limit" \
        --set=lower_limit="$lower_limit" \
        --set=rct_count="$rct_count" \
        --set=zscore="0" \
        --set=msScore="0" \
        --set=window_size="$window_size" \
        -f insert_ml_log.sql
    fi
  done

  # Step 2: Call the POST API
  api_response=$(echo "$api_payload" | curl -s -X POST "$API_URL" \
    -H "Authorization: Bearer $AUTH_TOKEN" \
    -H "Content-Type: application/json" \
    -d @-)

  # Step 3: Insert API response into ml_log
  echo "$api_response" | jq -c '.ml_respone[]' | while read -r item; do
    feed_id=$(echo "$item" | jq -r '.feed_id')
    feed_name=$(echo "$item" | jq -r '.feed_name')
    bus_date=$(echo "$item" | jq -r '.bus_date')
    upper_limit=$(echo "$item" | jq -r '.upper_limit')
    lower_limit=$(echo "$item" | jq -r '.lower_limit')
    rct_count=$(echo "$item" | jq -r '.rct_count')
    zscore=$(echo "$item" | jq -r '.zscore')
    msScore=$(echo "$item" | jq -r '.msScore')
    window_size=$(echo "$item" | jq -r '.window_size')

    psql \
      --set=feed_id="$feed_id" \
      --set=feed_name="$feed_name" \
      --set=bus_date="$bus_date" \
      --set=upper_limit="$upper_limit" \
      --set=lower_limit="$lower_limit" \
      --set=rct_count="$rct_count" \
      --set=zscore="$zscore" \
      --set=msScore="$msScore" \
      --set=window_size="$window_size" \
      -f insert_ml_log.sql
  done
done



INSERT INTO ml_log (
  feed_id,
  feed_name,
  bus_date,
  upper_limit,
  lower_limit,
  rct_count,
  zscore,
  msScore,
  window_size
)
VALUES (
  :'feed_id',
  :'feed_name',
  :'bus_date',
  :'upper_limit',
  :'lower_limit',
  :'rct_count',
  :'zscore',
  :'msScore',
  :'window_size'
);

SELECT
  fd.feed_id,
  fd.feed_name,
  fd.bus_date,
  fd.window_size,
  fl.upper_limit,
  fl.lower_limit,
  fc.bus_date,
  fc.rct_count
FROM
  feed_def fd
JOIN feed_limit fl ON fl.feed_id = fd.feed_id
JOIN feed_count fc ON fc.feed_id = fd.feed_id
ORDER BY
  fd.feed_id,
  fc.bus_date;
ALTER TABLE ml_log ADD COLUMN processed BOOLEAN DEFAULT FALSE;

| Condition                | API `rct_config`       | `ml_log` inserts |
| ------------------------ | ---------------------- | ---------------- |
| `records == window_size` | All records            | All              |
| `records > window_size`  | All records            | All              |
| `records < window_size`  | **Only latest** record | All              |
| `records = 0`            | **No request made**    | 0                |
