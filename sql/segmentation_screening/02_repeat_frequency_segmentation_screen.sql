-- REPEAT FREQUENCY BEHAVIORAL SEGMENTATION SCREEN
-- Purpose: Check whether early repeat frequency gives usable user-level segment variation.
--
-- Candidate screened in README:
--   Repeat frequency = number of active days within the first 3 days after first_seen.

WITH early_3day_events AS (
  SELECT
      f.visitorid
      , TIMESTAMP_DIFF(e.timestamp, f.first_seen, DAY) AS day_index -- count how many days from first_seen to each event time
  FROM `retailrocket-473904.retailrocket_data.visitor_first_seen` AS f
  LEFT JOIN `retailrocket-473904.retailrocket_data.events_cleaned` AS e
    ON f.visitorid = e.visitorid
   AND e.timestamp >= f.first_seen
   AND e.timestamp < TIMESTAMP_ADD(f.first_seen, INTERVAL 3 DAY)
)
, per_user AS (
  SELECT
      visitorid
      , COUNT(DISTINCT day_index) AS active_days_first_3d -- count how many distinct day_index values each user had
  FROM early_3day_events
  GROUP BY visitorid
)
SELECT
    active_days_first_3d
    , COUNT(*) AS users
    , COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS pct_of_users_in_active_day_bucket
FROM per_user
GROUP BY active_days_first_3d
ORDER BY active_days_first_3d;
