-- BROWSING BREADTH BEHAVIORAL SEGMENTATION SCREEN
-- Purpose:
--   Check whether distinct items interacted with in the first 3 days after first_seen
--   gives usable and analytically meaningful user-level segment variation.
--


-- 1. Quick screen: 4-bucket distribution
-- Feature = distinct items interacted with in first 3 days
-- Buckets = 1_item, 2_items, 3_items, 4plus_items
WITH early_3day_events AS (
  SELECT
      f.visitorid
      , e.itemid
  FROM `retailrocket-473904.retailrocket_data.visitor_first_seen` AS f
  LEFT JOIN `retailrocket-473904.retailrocket_data.events_cleaned` AS e
    ON f.visitorid = e.visitorid
   AND e.timestamp >= f.first_seen
   AND e.timestamp < TIMESTAMP_ADD(f.first_seen, INTERVAL 3 DAY)
)
, per_user AS (
  SELECT
      visitorid
      , COUNT(DISTINCT itemid) AS distinct_items_3d
  FROM early_3day_events
  GROUP BY visitorid
)
, bucketed AS (
  SELECT
      visitorid
      , CASE
          WHEN distinct_items_3d = 1 THEN '1_item'
          WHEN distinct_items_3d = 2 THEN '2_items'
          WHEN distinct_items_3d = 3 THEN '3_items'
          WHEN distinct_items_3d >= 4 THEN '4plus_items'
          ELSE 'unknown'
        END AS segment_label
  FROM per_user
)
SELECT
    segment_label
    , COUNT(*) AS users
    , COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS pct_of_users
FROM bucketed
GROUP BY segment_label
ORDER BY
  CASE segment_label
    WHEN '1_item' THEN 1
    WHEN '2_items' THEN 2
    WHEN '3_items' THEN 3
    WHEN '4plus_items' THEN 4
    ELSE 5
  END;


-- 2. Quick screen: final 3-bucket distribution
-- Feature = distinct items interacted with in first 3 days
-- Buckets = 1_item, 2_3_items, 4plus_items
WITH early_3day_events AS (
  SELECT
      f.visitorid
      , e.itemid
  FROM `retailrocket-473904.retailrocket_data.visitor_first_seen` AS f
  LEFT JOIN `retailrocket-473904.retailrocket_data.events_cleaned` AS e
    ON f.visitorid = e.visitorid
   AND e.timestamp >= f.first_seen
   AND e.timestamp < TIMESTAMP_ADD(f.first_seen, INTERVAL 3 DAY)
)
, per_user AS (
  SELECT
      visitorid
      , COUNT(DISTINCT itemid) AS distinct_items_3d
  FROM early_3day_events
  GROUP BY visitorid
)
, bucketed AS (
  SELECT
      visitorid
      , CASE
          WHEN distinct_items_3d = 1 THEN '1_item'
          WHEN distinct_items_3d BETWEEN 2 AND 3 THEN '2_3_items'
          WHEN distinct_items_3d >= 4 THEN '4plus_items'
          ELSE 'unknown'
        END AS segment_label
  FROM per_user
)
SELECT
    segment_label
    , COUNT(*) AS users
    , COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS pct_of_users
FROM bucketed
GROUP BY segment_label
ORDER BY
  CASE segment_label
    WHEN '1_item' THEN 1
    WHEN '2_3_items' THEN 2
    WHEN '4plus_items' THEN 3
    ELSE 4
  END;

-- 3. Quick screen: check whether retention meaningfully differs across 3 buckets
-- Segment = distinct items interacted with in first 3 days
-- Buckets = 1_item, 2_3_items, 4plus_items
-- Outcome = later return behavior after the segment-definition window
--   retained_later_d7  = any return in days 3-7 after first_seen
--   retained_later_d14 = any return in days 3-14 after first_seen
WITH base AS (
  SELECT
      f.visitorid
      , f.first_seen
      , e.timestamp AS event_ts
      , e.itemid
  FROM `retailrocket-473904.retailrocket_data.visitor_first_seen` AS f
  LEFT JOIN `retailrocket-473904.retailrocket_data.events_cleaned` AS e
    ON f.visitorid = e.visitorid
   AND e.timestamp >= f.first_seen
)
, per_user AS (
  SELECT
      visitorid
      -- segment feature: distinct items interacted with in first 3 days
      , COUNT(DISTINCT CASE
          WHEN event_ts < TIMESTAMP_ADD(first_seen, INTERVAL 3 DAY)
          THEN itemid
        END) AS distinct_items_3d
      -- later D7 return behavior: any event in days 3-7
      , MAX(CASE
          WHEN event_ts >= TIMESTAMP_ADD(first_seen, INTERVAL 3 DAY)
           AND event_ts < TIMESTAMP_ADD(first_seen, INTERVAL 8 DAY)
          THEN 1 ELSE 0
        END) AS retained_later_d7
      -- later D14 return behavior: any event in days 3-14
      , MAX(CASE
          WHEN event_ts >= TIMESTAMP_ADD(first_seen, INTERVAL 3 DAY)
           AND event_ts < TIMESTAMP_ADD(first_seen, INTERVAL 15 DAY)
          THEN 1 ELSE 0
        END) AS retained_later_d14
  FROM base
  GROUP BY visitorid
)
, bucketed AS (
  SELECT
      visitorid
      , CASE
          WHEN distinct_items_3d = 1 THEN '1_item'
          WHEN distinct_items_3d BETWEEN 2 AND 3 THEN '2_3_items'
          WHEN distinct_items_3d >= 4 THEN '4plus_items'
          ELSE 'unknown'
        END AS segment_label
      , retained_later_d7
      , retained_later_d14
  FROM per_user
)
SELECT
    segment_label
    , COUNT(*) AS users
    , AVG(retained_later_d7) * 100 AS later_d7_retention_pct
    , AVG(retained_later_d14) * 100 AS later_d14_retention_pct
FROM bucketed
GROUP BY segment_label
ORDER BY
  CASE segment_label
    WHEN '1_item' THEN 1
    WHEN '2_3_items' THEN 2
    WHEN '4plus_items' THEN 3
    ELSE 4
  END;
