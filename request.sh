WITH ordered_data AS (
  SELECT
    feed_def_key,
    feed_inst_key,
    src_feed_def_key,
    src_feed_inst_key,
    feed_name,
    src_feed_name,
    src_feed_inst_name,
    TO_CHAR(business_date, 'YYYY-MM-DD') AS business_date,
    record_count,
    iqr_lower_threshold,
    iqr_upper_threshold,
    zscore,
    gmm_lower_threshold,
    gmm_upper_threshold,
    COALESCE(iqr_outlier, '') AS iqr_outlier,
    COALESCE(zscore_outlier, '') AS zscore_outlier,
    COALESCE(if_outlier, '') AS if_outlier,
    COALESCE(gmm_outlier, '') AS gmm_outlier,
    anomaly_percentage,
    TO_CHAR(last_updated_on, 'YYYY-MM-DD"T"HH24:MI:SS') AS last_updated_on
  FROM t_dqp_adaptive_threshold_log
  WHERE feed_def_key = '$feed_def_key'
  ORDER BY business_date DESC
  LIMIT $threshold_window
)

SELECT COALESCE(json_agg(json_build_object(
  'feedDefKey', feed_def_key,
  'feedInstKey', feed_inst_key,
  'srcFeedDefKey', src_feed_def_key,
  'srcFeedInstKey', src_feed_inst_key,
  'feedName', feed_name,
  'srcFeedName', src_feed_name,
  'srcFeedInstName', src_feed_inst_name,
  'businessDate', business_date,
  'recordCount', record_count,
  'iqrLowerThreshold', iqr_lower_threshold,
  'iqrUpperThreshold', iqr_upper_threshold,
  'zscore', zscore,
  'gmmLowerThreshold', gmm_lower_threshold,
  'gmmUpperThreshold', gmm_upper_threshold,
  'iqrOutlier', iqr_outlier,
  'zscoreOutlier', zscore_outlier,
  'ifOutlier', if_outlier,
  'gmmOutlier', gmm_outlier,
  'anomalyPercentage', anomaly_percentage,
  'lastUpdatedOn', last_updated_on
)), '[]')
FROM ordered_data;
