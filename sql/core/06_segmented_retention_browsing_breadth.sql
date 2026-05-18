-- Purpose:
--   Create the segmented exact-day retention output table
--   by early browsing breadth.
--
-- Segmentation definition:
--   Users are grouped by the number of distinct items interacted with
--   during their first 3 days after first_seen:
--     - 1_item
--     - 2_or_3_items
--     - 4_plus_items
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
--

CREATE OR REPLACE TABLE `retailrocket-473904.retailrocket_data.segmented_retention_data` AS

-- 1. Define the end of the observable dataset
WITH dataset_end AS (
  SELECT MAX(`timestamp`) AS max_ts
  FROM `retailrocket-473904.retailrocket_data.events_cleaned`
)
-- 2. Define the population by excluding boundary cohort weeks
, eligible_users AS (
  SELECT fs.visitorid
      , fs.first_seen
      , DATE_TRUNC(DATE(fs.first_seen), ISOWEEK) AS cohort_week
  FROM `retailrocket-473904.retailrocket_data.visitor_first_seen` AS fs
  WHERE DATE_TRUNC(DATE(fs.first_seen), ISOWEEK) NOT IN (
    DATE '2015-04-27',
    DATE '2015-09-14'
  )
)
-- 3. Attach event activity and calculate how many whole days after first_seen each event happened
, user_day_activity AS (
  SELECT f.visitorid
      , f.first_seen
      , e.`timestamp`
      , TIMESTAMP_DIFF(e.`timestamp`, f.first_seen, DAY) AS day_diff
      , e.itemid
  FROM eligible_users AS f
  LEFT JOIN `retailrocket-473904.retailrocket_data.events_cleaned` AS e
    ON f.visitorid = e.visitorid
)
-- 4. Define early browsing-breadth segments based on distinct items interacted with in the first 3 days after first_seen
, segment_flag AS (
  SELECT visitorid
      , COUNT(DISTINCT itemid) AS distinct_items
      , CASE
          WHEN COUNT(DISTINCT itemid) = 1 THEN '1_item'
          WHEN COUNT(DISTINCT itemid) = 2
            OR COUNT(DISTINCT itemid) = 3 THEN '2_or_3_items'
          WHEN COUNT(DISTINCT itemid) >= 4 THEN '4_plus_items'
        END AS segment
  FROM user_day_activity
  WHERE day_diff IN (0, 1, 2)
  GROUP BY visitorid
)
-- 5. Create user-level exact-day return flags for D1, D7, D14, and D30
, return_flag AS (
  SELECT uda.visitorid
      , sf.segment
      , MAX(IF(uda.day_diff = 1, 1, 0)) AS retained_d1
      , MAX(IF(uda.day_diff = 7, 1, 0)) AS retained_d7
      , MAX(IF(uda.day_diff = 14, 1, 0)) AS retained_d14
      , MAX(IF(uda.day_diff = 30, 1, 0)) AS retained_d30
  FROM user_day_activity AS uda
  LEFT JOIN segment_flag AS sf
    ON uda.visitorid = sf.visitorid
  GROUP BY uda.visitorid, sf.segment
  HAVING segment IS NOT NULL
)
, user_maturity AS (
  SELECT fs.visitorid
        -- max_ts must reach the upper bound of each exact-day retention window
      , de.max_ts >= TIMESTAMP_ADD(fs.first_seen, INTERVAL 2 DAY) AS is_mature_d1
      , de.max_ts >= TIMESTAMP_ADD(fs.first_seen, INTERVAL 8 DAY) AS is_mature_d7
      , de.max_ts >= TIMESTAMP_ADD(fs.first_seen, INTERVAL 15 DAY) AS is_mature_d14
      , de.max_ts >= TIMESTAMP_ADD(fs.first_seen, INTERVAL 31 DAY) AS is_mature_d30
  FROM eligible_users AS fs
  CROSS JOIN dataset_end AS de
)
, per_segment AS (
  SELECT segment
      , COUNTIF(is_mature_d1) AS d1_mature_users
      , SUM(IF(is_mature_d1, retained_d1, 0)) AS d1_retained_users
      , COUNTIF(is_mature_d7) AS d7_mature_users
      , SUM(IF(is_mature_d7, retained_d7, 0)) AS d7_retained_users
      , COUNTIF(is_mature_d14) AS d14_mature_users
      , SUM(IF(is_mature_d14, retained_d14, 0)) AS d14_retained_users
      , COUNTIF(is_mature_d30) AS d30_mature_users
      , SUM(IF(is_mature_d30, retained_d30, 0)) AS d30_retained_users
  FROM return_flag AS rf
  INNER JOIN user_maturity AS um
    ON rf.visitorid = um.visitorid
  GROUP BY segment
)
SELECT segment
    , SAFE_DIVIDE(d1_retained_users, d1_mature_users) AS D1_retention
    , SAFE_DIVIDE(d7_retained_users, d7_mature_users) AS D7_retention
    , SAFE_DIVIDE(d14_retained_users, d14_mature_users) AS D14_retention
    , SAFE_DIVIDE(d30_retained_users, d30_mature_users) AS D30_retention
FROM per_segment
ORDER BY CASE
          WHEN segment = '1_item' THEN 1
          WHEN segment = '2_or_3_items' THEN 2
          WHEN segment = '4_plus_items' THEN 3
          ELSE 4
        END;


-- 9. Format the segmented retention table
SELECT segment
    , ROUND(D1_retention * 100, 2) AS D1_retention
    , ROUND(D7_retention * 100, 2) AS D7_retention
    , ROUND(D14_retention * 100, 2) AS D14_retention
    , ROUND(D30_retention * 100, 2) AS D30_retention
FROM `retailrocket-473904.retailrocket_data.segmented_retention_data`;