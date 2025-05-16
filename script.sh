#!/bin/bash

set -e

FEED_ID=$1
BUS_DATE=$2

DB_HOST="localhost"
DB_NAME="your_db"
DB_USER="your_user"
API_URL="https://your-api-url.com/endpoint"
AUTH_TOKEN="Bearer your_token"
SQL_DIR="./sql"

# Helper to run SQL with substitution
run_sql() {
  sed "s/:FEED_ID/$FEED_ID/g" "$1" | psql -h "$DB_HOST" -d "$DB_NAME" -U "$DB_USER" -t -A -F"," 
}

# === Step 1: Fetch feed info from feed_def, feed_limit, feed_count
read -r FEED_NAME WINDOW_SIZE <<< "$(run_sql "$SQL_DIR/select_feed_info.sql" | sed -n 1p | awk -F',' '{print $1, $2}')"
read -r UPPER_LIMIT LOWER_LIMIT <<< "$(run_sql "$SQL_DIR/select_feed_info.sql" | sed -n 2p | awk -F',' '{print $1, $2}')"
RCT_COUNT=$(run_sql "$SQL_DIR/select_feed_info.sql" | sed -n 3p)
RECORD_COUNT=$(run_sql "$SQL_DIR/select_feed_info.sql" | sed -n 4p | xargs)

# === Step 2: Function to call POST API and insert response
call_post_api_and_log() {
  echo "Calling POST API..."
  RESPONSE=$(curl -s -X POST "$API_URL" \
    -H "Authorization: $AUTH_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"feed_id\": $FEED_ID,
      \"feed_name\": \"$FEED_NAME\",
      \"bus_date\": \"$BUS_DATE\",
      \"upper_limit\": $UPPER_LIMIT,
      \"lower_limit\": $LOWER_LIMIT,
      \"rct_count\": $RCT_COUNT,
      \"zscore\": 0,
      \"msScore\": 0,
      \"window_size\": $WINDOW_SIZE
    }")

  echo "$RESPONSE" | jq -c '.ml_respone[]' | while read -r row; do
    FEED_ID_VAL=$(echo "$row" | jq '.feed_id')
    FEED_NAME_VAL=$(echo "$row" | jq -r '.feed_name')
    BUS_DATE_VAL=$(echo "$row" | jq -r '.bus_date')
    UPPER=$(echo "$row" | jq '.upper_limit')
    LOWER=$(echo "$row" | jq '.lower_limit')
    RCT=$(echo "$row" | jq '.rct_count')
    ZSCORE=$(echo "$row" | jq '.zscore')
    MSCORE=$(echo "$row" | jq '.msScore')
    WIN_SIZE=$(echo "$row" | jq '.window_size')

    # Prepare INSERT SQL
    INSERT_SQL=$(sed -e "s/:FEED_ID/$FEED_ID_VAL/" \
                     -e "s|:FEED_NAME|$FEED_NAME_VAL|" \
                     -e "s|:BUS_DATE|$BUS_DATE_VAL|" \
                     -e "s/:UPPER_LIMIT/$UPPER/" \
                     -e "s/:LOWER_LIMIT/$LOWER/" \
                     -e "s/:RCT_COUNT/$RCT/" \
                     -e "s/:ZSCORE/$ZSCORE/" \
                     -e "s/:MSCORE/$MSCORE/" \
                     -e "s/:WINDOW_SIZE/$WIN_SIZE/" \
                     "$SQL_DIR/feed_records_and_insert.sql" | tail -n 1)

    echo "$INSERT_SQL" | psql -h "$DB_HOST" -d "$DB_NAME" -U "$DB_USER"
  done
}

# === Step 3: Case Handling
if [[ "$RECORD_COUNT" -eq 0 ]]; then
  echo "CASE 1: No records found, calling API"
  call_post_api_and_log

elif [[ "$RECORD_COUNT" -lt "$WINDOW_SIZE" ]]; then
  echo "CASE 2: Found partial records, inserting and calling API"

  # Extract all SELECT statements, run only the SELECT part
  SELECT_PART=$(awk '/^-- SELECT Records/{flag=1;next}/^-- INSERT Template/{flag=0}flag' "$SQL_DIR/feed_records_and_insert.sql")
  echo "$SELECT_PART" | sed "s/:FEED_ID/$FEED_ID/g" | psql -h "$DB_HOST" -d "$DB_NAME" -U "$DB_USER" -t -A -F"," | while IFS=',' read -r UPPER LOWER RCT; do

    INSERT_SQL=$(sed -e "s/:FEED_ID/$FEED_ID/" \
                     -e "s|:FEED_NAME|$FEED_NAME|" \
                     -e "s|:BUS_DATE|$BUS_DATE|" \
                     -e "s/:UPPER_LIMIT/$UPPER/" \
                     -e "s/:LOWER_LIMIT/$LOWER/" \
                     -e "s/:RCT_COUNT/$RCT/" \
                     -e "s/:ZSCORE/0/" \
                     -e "s/:MSCORE/0/" \
                     -e "s/:WINDOW_SIZE/$WINDOW_SIZE/" \
                     "$SQL_DIR/feed_records_and_insert.sql" | tail -n 1)

    echo "$INSERT_SQL" | psql -h "$DB_HOST" -d "$DB_NAME" -U "$DB_USER"
  done

  call_post_api_and_log
else
  echo "Sufficient records exist (>= window_size). Skipping API call."
fi

-- ================================
-- SELECT Records for CASE 2
-- ================================
-- Used to join feed_limit × feed_count by feed_id
-- Replace :FEED_ID with actual value in your shell script
-- =================================
SELECT fl.upper_limit, fl.lower_limit, fc.rct_count
FROM feed_limit fl
JOIN feed_count fc ON fl.feed_id = fc.feed_id
WHERE fl.feed_id = :FEED_ID;

-- ================================
-- INSERT Template for ml_log Table
-- ================================
-- Replace placeholders like :FEED_ID, :FEED_NAME, etc.
-- in your shell script before execution.
-- =================================
-- Use this template inside your shell script using `sed`
-- It will be looped for each row in the shell logic
INSERT INTO ml_log (
  feed_id, feed_name, bus_date, upper_limit,
  lower_limit, rct_count, zscore, msScore, window_size
) VALUES (
  :FEED_ID, ':FEED_NAME', ':BUS_DATE',
  :UPPER_LIMIT, :LOWER_LIMIT, :RCT_COUNT, :ZSCORE, :MSCORE, :WINDOW_SIZE
);

