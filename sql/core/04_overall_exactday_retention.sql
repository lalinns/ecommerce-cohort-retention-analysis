-- Purpose:
--Create the overall exact-day retention summary table at D1, D7, D14, and D30.
--
-- Retention definition:
--   A user is counted as retained at a checkpoint only if
--   they have at least one event of any type
--   on that exact checkpoint day after first_seen.
--
-- Denominator:
--   Retention is calculated only among mature users,
--   meaning users who have enough observable time in the dataset
--   to be fairly evaluated for that checkpoint.
--
-- Reporting scope:
--   The first and last weekly cohorts are excluded
--   to avoid dataset boundary effects.


CREATE OR REPLACE TABLE `retailrocket-473904.retailrocket_data.overall_exactday_retention_summary` AS

-- 1. Define the end of the observable dataset
WITH dataset_end AS (
  SELECT MAX(`timestamp`) AS max_ts
  FROM `retailrocket-473904.retailrocket_data.events_cleaned`
)
-- 2. Define the population by excluding boundary cohort weeks
, eligible_users AS (
  SELECT fs.visitorid
      , fs.first_seen
  FROM `retailrocket-473904.retailrocket_data.visitor_first_seen` AS fs
  WHERE DATE_TRUNC(DATE(fs.first_seen), ISOWEEK) NOT IN (
    DATE '2015-04-27',
    DATE '2015-09-14'
  )
)
-- 3. Capture exact-day return activity at D1, D7, D14, and D30
, user_day_activity AS (
  SELECT DISTINCT fs.visitorid
      , TIMESTAMP_DIFF(e.`timestamp`, fs.first_seen, DAY) AS day_bucket
  FROM eligible_users AS fs
  JOIN `retailrocket-473904.retailrocket_data.events_cleaned` AS e
    ON e.visitorid = fs.visitorid
  WHERE TIMESTAMP_DIFF(e.`timestamp`, fs.first_seen, DAY) IN (1, 7, 14, 30)
)
-- 4. return logic checks whether the user had activity inside that buckett
, user_return_flags AS (
  SELECT fs.visitorid
      , MAX(IF(uda.day_bucket = 1, 1, 0))  AS retained_d1
      , MAX(IF(uda.day_bucket = 7, 1, 0))  AS retained_d7
      , MAX(IF(uda.day_bucket = 14, 1, 0)) AS retained_d14
      , MAX(IF(uda.day_bucket = 30, 1, 0)) AS retained_d30
  FROM eligible_users AS fs
  LEFT JOIN user_day_activity AS uda
    ON fs.visitorid = uda.visitorid
  GROUP BY fs.visitorid
)
-- 5. checks whether each user has enough observed time to be fairly evaluated for D1, D7, D14, and D30
, user_maturity AS (
  SELECT fs.visitorid
        -- max_ts must reach the upper bound of each exact-day retention window
      , de.max_ts >= TIMESTAMP_ADD(fs.first_seen, INTERVAL 2 DAY)  AS is_mature_d1
      , de.max_ts >= TIMESTAMP_ADD(fs.first_seen, INTERVAL 8 DAY)  AS is_mature_d7
      , de.max_ts >= TIMESTAMP_ADD(fs.first_seen, INTERVAL 15 DAY) AS is_mature_d14
      , de.max_ts >= TIMESTAMP_ADD(fs.first_seen, INTERVAL 31 DAY) AS is_mature_d30
  FROM eligible_users AS fs
  CROSS JOIN dataset_end AS de
)
-- 6. Aggregate the overall exact-day retention summary
SELECT 1 AS checkpoint_order
    , 'D1' AS checkpoint
    , COUNTIF(um.is_mature_d1) AS mature_users
    , SUM(IF(um.is_mature_d1, urf.retained_d1, 0)) AS retained_users
    , SAFE_DIVIDE(
        SUM(IF(um.is_mature_d1, urf.retained_d1, 0))
        , COUNTIF(um.is_mature_d1)
      ) AS retention_rate
FROM user_maturity AS um
JOIN user_return_flags AS urf
ON um.visitorid = urf.visitorid

UNION ALL

SELECT 7 AS checkpoint_order
    , 'D7' AS checkpoint
    , COUNTIF(um.is_mature_d7) AS mature_users
    , SUM(IF(um.is_mature_d7, urf.retained_d7, 0)) AS retained_users
    , SAFE_DIVIDE(
        SUM(IF(um.is_mature_d7, urf.retained_d7, 0))
        , COUNTIF(um.is_mature_d7)
      ) AS retention_rate
FROM user_maturity AS um
JOIN user_return_flags AS urf
ON um.visitorid = urf.visitorid

UNION ALL

SELECT 14 AS checkpoint_order
    , 'D14' AS checkpoint
    , COUNTIF(um.is_mature_d14) AS mature_users
    , SUM(IF(um.is_mature_d14, urf.retained_d14, 0)) AS retained_users
    , SAFE_DIVIDE(
        SUM(IF(um.is_mature_d14, urf.retained_d14, 0))
        , COUNTIF(um.is_mature_d14)
      ) AS retention_rate
FROM user_maturity AS um
JOIN user_return_flags AS urf
ON um.visitorid = urf.visitorid

UNION ALL

SELECT 30 AS checkpoint_order
    , 'D30' AS checkpoint
    , COUNTIF(um.is_mature_d30) AS mature_users
    , SUM(IF(um.is_mature_d30, urf.retained_d30, 0)) AS retained_users
    , SAFE_DIVIDE(
        SUM(IF(um.is_mature_d30, urf.retained_d30, 0))
        , COUNTIF(um.is_mature_d30)
      ) AS retention_rate
FROM user_maturity AS um
JOIN user_return_flags AS urf
ON um.visitorid = urf.visitorid

ORDER BY checkpoint_order;


-- 7. Format the final output for reporting
SELECT checkpoint_order
    , checkpoint
    , mature_users
    , retained_users
    , ROUND(retention_rate * 100, 3) AS retention_rate_pct
FROM `retailrocket-473904.retailrocket_data.overall_exactday_retention_summary`;