-- Purpose:
--Create the weekly cohort exact-day retention output table used for the cohort retention heatmap.
--
-- Retention definition:
--   A user is counted as retained at D1, D7, D14, or D30
--   only if they have at least one event of any type
--   on that exact checkpoint day after first_seen.
--
-- Denominator:
--   Retention is calculated only among mature users,
--   meaning users who have enough observable time in the dataset
--   to be fairly evaluated for that checkpoint.


CREATE OR REPLACE TABLE `retailrocket-473904.retailrocket_data.weekly_cohort_heatmap` AS
-- 1. Define the end of the observable dataset
WITH dataset_end AS (
  SELECT MAX(`timestamp`) AS max_ts
  FROM `retailrocket-473904.retailrocket_data.events_cleaned`
)
-- 2. Assign users to weekly first_seen cohorts
, user_cohort AS (
  SELECT fs.visitorid
      , fs.first_seen
      , DATE_TRUNC(DATE(fs.first_seen), ISOWEEK) AS cohort_week
  FROM `retailrocket-473904.retailrocket_data.visitor_first_seen` AS fs
)
-- 3. Keep distinct visitorid + day_diff combinations for the exact-day retention windows: D1, D7, D14, and D30
, user_day_activity AS (
  SELECT DISTINCT uc.visitorid
      , TIMESTAMP_DIFF(e.`timestamp`, uc.first_seen, DAY) AS day_diff
        -- calculate how many whole days after first_seen each event happened
  FROM user_cohort AS uc
  JOIN `retailrocket-473904.retailrocket_data.events_cleaned` AS e
    ON e.visitorid = uc.visitorid
  WHERE TIMESTAMP_DIFF(e.`timestamp`, uc.first_seen, DAY) IN (1, 7, 14, 30)
)
-- 4. Mark whether each retained event belongs to D1, D7, D14, or D30
, mark_day_diff AS (
  SELECT uc.visitorid
      , uc.cohort_week
      , uda.day_diff
      , IF(uda.day_diff = 1, 1, 0) AS if_d1
      , IF(uda.day_diff = 7, 1, 0) AS if_d7
      , IF(uda.day_diff = 14, 1, 0) AS if_d14
      , IF(uda.day_diff = 30, 1, 0) AS if_d30
  FROM user_cohort AS uc
  LEFT JOIN user_day_activity AS uda
    ON uc.visitorid = uda.visitorid
)
-- 5. return logic checks whether the user had activity inside that window
, user_return_flags AS (
  SELECT visitorid
      , cohort_week
      , MAX(if_d1) AS retained_d1
      , MAX(if_d7) AS retained_d7
      , MAX(if_d14) AS retained_d14
      , MAX(if_d30) AS retained_d30
  FROM mark_day_diff
  GROUP BY visitorid, cohort_week
)
-- 6. checks whether each user has enough observed time to be fairly evaluated for D1, D7, D14, and D30
, user_maturity AS (
  SELECT uc.visitorid
      , uc.cohort_week
        -- max_ts must reach the upper bound of each exact-day retention window
      , de.max_ts >= TIMESTAMP_ADD(uc.first_seen, INTERVAL 2 DAY) AS is_mature_d1
      , de.max_ts >= TIMESTAMP_ADD(uc.first_seen, INTERVAL 8 DAY) AS is_mature_d7
      , de.max_ts >= TIMESTAMP_ADD(uc.first_seen, INTERVAL 15 DAY) AS is_mature_d14
      , de.max_ts >= TIMESTAMP_ADD(uc.first_seen, INTERVAL 31 DAY) AS is_mature_d30
  FROM user_cohort AS uc
  CROSS JOIN dataset_end AS de
)
-- 7. Calculate total cohort size before checkpoint-specific maturity filtering
, cohort_size AS (
  SELECT cohort_week
      , COUNT(*) AS cohort_users
  FROM user_cohort
  GROUP BY cohort_week
)
-- 8. Aggregate weekly cohort retention
--    for D1, D7, D14, and D30
SELECT um.cohort_week
    , 1 AS checkpoint_order
    , 'D1' AS checkpoint
    , cs.cohort_users
    , COUNTIF(um.is_mature_d1) AS mature_users
    , SUM(IF(um.is_mature_d1, urf.retained_d1, 0)) AS retained_users
    , SAFE_DIVIDE(
        SUM(IF(um.is_mature_d1, urf.retained_d1, 0))
        , COUNTIF(um.is_mature_d1)
      ) AS retention_rate
FROM user_maturity AS um
JOIN user_return_flags AS urf
  USING (visitorid, cohort_week)
JOIN cohort_size AS cs
  USING (cohort_week)
GROUP BY um.cohort_week
    , checkpoint_order
    , checkpoint
    , cs.cohort_users

UNION ALL

SELECT um.cohort_week
    , 7 AS checkpoint_order
    , 'D7' AS checkpoint
    , cs.cohort_users
    , COUNTIF(um.is_mature_d7) AS mature_users
    , SUM(IF(um.is_mature_d7, urf.retained_d7, 0)) AS retained_users
    , SAFE_DIVIDE(
        SUM(IF(um.is_mature_d7, urf.retained_d7, 0))
        , COUNTIF(um.is_mature_d7)
      ) AS retention_rate
FROM user_maturity AS um
JOIN user_return_flags AS urf
  USING (visitorid, cohort_week)
JOIN cohort_size AS cs
  USING (cohort_week)
GROUP BY um.cohort_week
    , checkpoint_order
    , checkpoint
    , cs.cohort_users

UNION ALL

SELECT um.cohort_week
    , 14 AS checkpoint_order
    , 'D14' AS checkpoint
    , cs.cohort_users
    , COUNTIF(um.is_mature_d14) AS mature_users
    , SUM(IF(um.is_mature_d14, urf.retained_d14, 0)) AS retained_users
    , SAFE_DIVIDE(
        SUM(IF(um.is_mature_d14, urf.retained_d14, 0))
        , COUNTIF(um.is_mature_d14)
      ) AS retention_rate
FROM user_maturity AS um
JOIN user_return_flags AS urf
  USING (visitorid, cohort_week)
JOIN cohort_size AS cs
  USING (cohort_week)
GROUP BY um.cohort_week
    , checkpoint_order
    , checkpoint
    , cs.cohort_users

UNION ALL

SELECT um.cohort_week
    , 30 AS checkpoint_order
    , 'D30' AS checkpoint
    , cs.cohort_users
    , COUNTIF(um.is_mature_d30) AS mature_users
    , SUM(IF(um.is_mature_d30, urf.retained_d30, 0)) AS retained_users
    , SAFE_DIVIDE(
        SUM(IF(um.is_mature_d30, urf.retained_d30, 0))
        , COUNTIF(um.is_mature_d30)
      ) AS retention_rate
FROM user_maturity AS um
JOIN user_return_flags AS urf
  USING (visitorid, cohort_week)
JOIN cohort_size AS cs
  USING (cohort_week)
GROUP BY um.cohort_week
    , checkpoint_order
    , checkpoint
    , cs.cohort_users;