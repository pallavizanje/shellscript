SELECT COALESCE(json_agg(json_build_object(
  'feedDefKey', feed_def_key,
  'feedInstKey', feed_inst_key,
  'srcFeedDefKey', src_feed_def_key,
  'srcFeedInstKey', src_feed_inst_key,
  'feedName', feed_name,
  'srcFeedName', src_feed_name,
  'srcFeedInstName', src_feed_inst_name,
  'businessDate', TO_CHAR(business_date, 'YYYY-MM-DD'),
  'recordCount', record_count,
  'iqrLowerThreshold', iqr_lower_threshold,
  'iqrUpperThreshold', iqr_upper_threshold,
  'zscore', zscore,
  'gmmLowerThreshold', gmm_lower_threshold,
  'gmmUpperThreshold', gmm_upper_threshold,
  'iqrOutlier', COALESCE(iqr_outlier, ''),
  'zscoreOutlier', COALESCE(zscore_outlier, ''),
  'ifOutlier', COALESCE(if_outlier, ''),
  'gmmOutlier', COALESCE(gmm_outlier, ''),
  'anomalyPercentage', anomaly_percentage,
  'lastUpdatedOn', TO_CHAR(last_updated_on, 'YYYY-MM-DD"T"HH24:MI:SS')
)), '[]')
FROM t_dqp_adaptive_threshold_log
WHERE feed_def_key = '$feed_def_key'
ORDER BY business_date DESC
LIMIT $threshold_window;
