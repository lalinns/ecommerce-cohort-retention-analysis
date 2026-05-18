-- Purpose:
-- Check whether the cleaned event data is suitable for cohort-based retention analysis.
-- This file assumes: events_cleaned has already been created and visitor_first_seen has already been created


-- 1. Event timeline and volume stability
  --a/ Event timeline continuity check
  -- Goal: Check whether there are any missing calendar days between the earliest and latest event dates.
  WITH event_dates AS (
  SELECT DISTINCT DATE(`timestamp`) AS dates
  FROM `retailrocket-473904.retailrocket_data.events_cleaned`
  )
  , minmax AS (
    SELECT MIN(DATE(`timestamp`)) AS start_date
          , MAX(DATE(`timestamp`)) AS end_date
    FROM `retailrocket-473904.retailrocket_data.events_cleaned`
  )
  , calendar_dates AS (
    SELECT full_date
    FROM minmax
    , UNNEST(GENERATE_DATE_ARRAY(start_date, end_date)) AS full_date
  )
  SELECT c.full_date
  FROM calendar_dates AS c
  LEFT JOIN event_dates AS e
  ON c.full_date = e.dates
  WHERE e.dates IS NULL;


  --b/ Event volume stability check
  -- Goal: Inspect monthly event counts to check for abnormal collapse in activity across the dataset timeline.
  SELECT FORMAT_DATE('%Y-%m', DATE(`timestamp`)) AS ym
        , COUNT(*) AS n
  FROM `retailrocket-473904.retailrocket_data.events_cleaned`
  GROUP BY 1
  ORDER BY 1;


-- 2. Cohort anchor viability check
-- Goal: Inspect the distribution of first_seen dates to check whether the proxy cohort anchor appears usable for retention analysis.
SELECT DATE(first_seen) AS `date`
      , COUNT(*) AS new_users
FROM `retailrocket-473904.retailrocket_data.visitor_first_seen`
GROUP BY DATE(first_seen)
ORDER BY DATE(first_seen);


-- 3. Retention window sufficiency
--Goal: Check whether the dataset timeline is long enough to support D7, D14, and D30 retention windows.
WITH bounds AS (
  SELECT DATE(MAX(`timestamp`)) AS max_event_date
  FROM `retailrocket-473904.retailrocket_data.events_cleaned`
)
, limits AS (
  SELECT max_event_date
        , DATE_SUB(max_event_date, INTERVAL 7 DAY) AS d7_limit
        , DATE_SUB(max_event_date, INTERVAL 14 DAY) AS d14_limit
        , DATE_SUB(max_event_date, INTERVAL 30 DAY) AS d30_limit
  FROM bounds
)
SELECT
        (SELECT max_event_date FROM limits) AS max_event_date
      , (SELECT d7_limit FROM limits) AS latest_eligible_first_seen_for_d7
      , (SELECT d14_limit FROM limits) AS latest_eligible_first_seen_for_d14
      , (SELECT d30_limit FROM limits) AS latest_eligible_first_seen_for_d30
      , COUNT(*) AS total_users

        -- how many users can be analyzed for D7 retention
      , COUNTIF(DATE(first_seen) <= (SELECT d7_limit FROM limits)) AS eligible_for_d7

        -- how many users can be analyzed for D14 retention
      , COUNTIF(DATE(first_seen) <= (SELECT d14_limit FROM limits)) AS eligible_for_d14

        -- how many users can be analyzed for D30 retention
      , COUNTIF(DATE(first_seen) <= (SELECT d30_limit FROM limits)) AS eligible_for_d30
FROM `retailrocket-473904.retailrocket_data.visitor_first_seen`;



-- 4. Weekly cohort stability and boundary effects
-- Goal Check whether weekly cohort sizes are stable enough for cohort retention comparison, and identify possible boundary cohorts.
SELECT DATE_TRUNC(DATE(first_seen), ISOWEEK) AS cohort_week
      , COUNT(*) AS new_users
FROM `retailrocket-473904.retailrocket_data.visitor_first_seen`
GROUP BY 1
ORDER BY 1;


-- 5. Post-anchor return signal
-- Goal: Confirm that meaningful post-anchor return behavior exists before building the final exact-day retention tables.
  --a/ Join anchors with events and compute day difference from first_seen
  WITH event_with_day_diff AS (
    SELECT v.visitorid
        ,  v.first_seen
        ,  e.timestamp AS event_ts

          -- how many whole days after first_seen did this event happen
        ,  TIMESTAMP_DIFF(e.timestamp, v.first_seen, DAY) AS days_since_first
    FROM `retailrocket-473904.retailrocket_data.visitor_first_seen` AS v
    JOIN `retailrocket-473904.retailrocket_data.events_cleaned` AS e
    ON v.visitorid = e.visitorid
  )

  --b/ For each event, flag whether it falls into each cumulative return window
  , event_flag AS (
    SELECT visitorid
        ,  CASE WHEN days_since_first = 1 THEN 1 ELSE 0 END AS flag_d1
        ,  CASE WHEN days_since_first BETWEEN 1 AND 7 THEN 1 ELSE 0 END AS flag_d1_d7
        ,  CASE WHEN days_since_first BETWEEN 1 AND 14 THEN 1 ELSE 0 END AS flag_d1_d14
    FROM event_with_day_diff
  )

  --c/ For each visitor, flag whether they had at least one event in each cumulative post-anchor window
  , visitor_flag AS (
    SELECT visitorid

          -- at least one event on exact Day 1 after first_seen
        ,  MAX(flag_d1) AS has_return_d1

          -- at least one event during D1-D7 after first_seen
        ,  MAX(flag_d1_d7) AS has_return_d1_d7

          -- at least one event during D1-D14 after first_seen
        ,  MAX(flag_d1_d14) AS has_return_d1_d14
    FROM event_flag
    GROUP BY visitorid
  )

  --d/ Aggregate visitor-level flags to get diagnostic cumulative return rates
  SELECT
          AVG(has_return_d1) AS d1_cumulative_return_rate
        , AVG(has_return_d1_d7) AS d1_d7_cumulative_return_rate
        , AVG(has_return_d1_d14) AS d1_d14_cumulative_return_rate
  FROM visitor_flag;













