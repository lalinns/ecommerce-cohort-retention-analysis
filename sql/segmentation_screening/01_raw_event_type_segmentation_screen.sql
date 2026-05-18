-- RAW EVENT-TYPE BEHAVIORAL SEGMENTATION SCREEN
-- Purpose:
--   Check whether raw event-type behavior gives usable user-level segment variation.
--   This file combines the Day-0 and first-3-day screening queries.


-- 1. Day-0 raw event-type distribution
WITH extract_events_cleaned AS (
  SELECT
      `timestamp` AS event_ts
      , visitorid
      , event
      , itemid
  FROM `retailrocket-473904.retailrocket_data.events_cleaned`
)
, extract_visitor_first_seen AS (
  SELECT
      first_seen
      , visitorid
  FROM `retailrocket-473904.retailrocket_data.visitor_first_seen`
)
, events_in_day0 AS (
  SELECT
      f.visitorid
      , f.first_seen
      , e.event
  FROM extract_visitor_first_seen AS f
  LEFT JOIN extract_events_cleaned AS e
    ON f.visitorid = e.visitorid
   AND e.event_ts >= f.first_seen -- use inclusive lower bound
   AND e.event_ts < TIMESTAMP_ADD(f.first_seen, INTERVAL 1 DAY) -- exclusive upper bound keeps the windows clean and non-overlapping
)
, per_user AS (
  SELECT
      visitorid
      , COUNT(DISTINCT event) AS total_unique_events
      , MIN(event) AS single_event
  FROM events_in_day0
  GROUP BY visitorid
)
SELECT
    total_unique_events
    , COUNT(*) AS users
    , COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS pct_of_users
FROM per_user
GROUP BY total_unique_events
ORDER BY total_unique_events;


-- 2. Day-0 single-event-type dominance check
--   This diagnostic supports the interpretation that the concentrated bucket is mostly view behavior.
WITH extract_events_cleaned AS (
  SELECT
      `timestamp` AS event_ts
      , visitorid
      , event
      , itemid
  FROM `retailrocket-473904.retailrocket_data.events_cleaned`
)
, extract_visitor_first_seen AS (
  SELECT
      first_seen
      , visitorid
  FROM `retailrocket-473904.retailrocket_data.visitor_first_seen`
)
, events_in_day0 AS (
  SELECT
      f.visitorid
      , f.first_seen
      , e.event
  FROM extract_visitor_first_seen AS f
  LEFT JOIN extract_events_cleaned AS e
    ON f.visitorid = e.visitorid
   AND e.event_ts >= f.first_seen
   AND e.event_ts < TIMESTAMP_ADD(f.first_seen, INTERVAL 1 DAY)
)
, per_user AS (
  SELECT
      visitorid
      , COUNT(DISTINCT event) AS total_unique_events
      , MIN(event) AS single_event
  FROM events_in_day0
  GROUP BY visitorid
)
SELECT
    single_event AS event
    , COUNT(*) AS users
    , COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS pct_among_1_event_type_users
FROM per_user
WHERE total_unique_events = 1
GROUP BY single_event
ORDER BY users DESC;



-- 3. First-3-day raw event-type distribution
WITH early_3day_events AS (
  SELECT
      f.visitorid
      , f.first_seen
      , e.event
  FROM `retailrocket-473904.retailrocket_data.visitor_first_seen` AS f
  LEFT JOIN `retailrocket-473904.retailrocket_data.events_cleaned` AS e
    ON f.visitorid = e.visitorid
   AND e.timestamp >= f.first_seen
   AND e.timestamp < TIMESTAMP_ADD(f.first_seen, INTERVAL 3 DAY) -- day is defined as exactly 24h
)
, per_user AS (
  SELECT
      visitorid
      , COUNT(DISTINCT event) AS total_unique_events
      , MIN(event) AS single_event
  FROM early_3day_events
  GROUP BY visitorid
)
SELECT
    total_unique_events
    , COUNT(*) AS users
    , COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS pct_of_users
FROM per_user
GROUP BY total_unique_events
ORDER BY total_unique_events;


-- 4. First-3-day single-event-type dominance check
--   This diagnostic supports the interpretation that the concentrated bucket is mostly view behavior.

WITH early_3day_events AS (
  SELECT
      f.visitorid
      , f.first_seen
      , e.event
  FROM `retailrocket-473904.retailrocket_data.visitor_first_seen` AS f
  LEFT JOIN `retailrocket-473904.retailrocket_data.events_cleaned` AS e
    ON f.visitorid = e.visitorid
   AND e.timestamp >= f.first_seen
   AND e.timestamp < TIMESTAMP_ADD(f.first_seen, INTERVAL 3 DAY)
)
, per_user AS (
  SELECT
      visitorid
      , COUNT(DISTINCT event) AS total_unique_events
      , MIN(event) AS single_event
  FROM early_3day_events
  GROUP BY visitorid
)
SELECT
    single_event AS event
    , COUNT(*) AS users
    , COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS pct_among_1_event_type_users
FROM per_user
WHERE total_unique_events = 1
GROUP BY single_event
ORDER BY users DESC;
