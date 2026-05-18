-- Purpose:
-- Prepare the raw events table and materialize events_cleaned

-- 1. Check timestamp values before conversion
  -- Verify all `timestamp` values in events table are valid integers before conversion
  SELECT COUNT(*) AS non_castable_rows -- Count non-castable integers (should be 0)
  FROM `retailrocket-473904.retailrocket_data.events`
  WHERE SAFE_CAST(`timestamp` AS INT64) IS NULL 
  AND `timestamp` IS NOT NULL;


-- 2. Convert timestamp column into UTC TIMESTAMP format
  -- Convert data type of timestamp column in events table to TIMESTAMP
  CREATE OR REPLACE TABLE `retailrocket-473904.retailrocket_data.events_converted` AS  -- create a new table with converted timestamp column
  SELECT TIMESTAMP_MILLIS(`timestamp`) AS `timestamp`
      , visitorid
      , event
      , itemid 
      , transactionid
  FROM `retailrocket-473904.retailrocket_data.events`;


-- 3. Check missing / NULL values in required fields
SELECT COUNTIF(`timestamp` IS NULL) AS null_ts
    , COUNTIF(visitorid IS NULL) AS null_visitor
    , COUNTIF(event IS NULL) AS null_event
    -- NULL for itemid may be valid, therefore, check missing itemid only where it's required
    , COUNTIF(event IN ('view', 'addtocart', 'transaction') AND itemid IS NULL) AS missing_itemid
    -- NULL is expected for transactionid, therefore, check missing transactionid only where it's required
    , COUNTIF(event = 'transaction' AND transactionid IS NULL) AS missing_transactionid
FROM `retailrocket-473904.retailrocket_data.events_converted`;


-- 4. Identify and removed duplicate event logs by event identity, not necessarily exact duplicate rows
CREATE OR REPLACE TABLE `retailrocket-473904.retailrocket_data.events_dedup` AS
SELECT `timestamp`, visitorid, event, itemid, transactionid
FROM (
SELECT *
      , ROW_NUMBER() OVER (
            PARTITION BY `timestamp`, visitorid, event, itemid 
            ORDER BY `timestamp`
        ) AS rn
FROM `retailrocket-473904.retailrocket_data.events_converted`
) AS tbl
WHERE rn = 1;


-- 5. Verify that event names are limited to expected values
SELECT event
    , COUNT(*) AS n
FROM `retailrocket-473904.retailrocket_data.events_dedup`
GROUP BY event
ORDER BY n DESC;


-- 6. Check transactionid consistency
  -- Verify all `transaction` events have transactionid
  SELECT *
  FROM `retailrocket-473904.retailrocket_data.events_dedup`
  WHERE event = 'transaction' 
  AND transactionid IS NULL;


  -- Verify only `transaction` events have transactionid 
  SELECT *
  FROM `retailrocket-473904.retailrocket_data.events_dedup`
  WHERE event <> 'transaction' 
    AND transactionid IS NOT NULL;


-- 7. Validate that timestamps fall within a realistic observation window
  -- Check timestamp outliers
  SELECT MIN(`timestamp`) AS min_ts
      , MAX(`timestamp`) AS max_ts
      -- The goal is to catch impossible or corrupted timestamps (reality check)
      , COUNTIF(`timestamp` > TIMESTAMP_ADD(CURRENT_TIMESTAMP(), INTERVAL 1 DAY)) AS from_future
  FROM `retailrocket-473904.retailrocket_data.events_dedup`;


-- 8. Create events_cleaned table
CREATE OR REPLACE TABLE `retailrocket-473904.retailrocket_data.events_cleaned` AS
SELECT *
FROM `retailrocket-473904.retailrocket_data.events_dedup`;


-- 9. Count rows before and after cleaning
SELECT 'events_converted' AS table_name
    , COUNT(*) AS n_rows 
FROM `retailrocket-473904.retailrocket_data.events_converted`

UNION ALL

SELECT 'events_cleaned'
    , COUNT(*) 
FROM `retailrocket-473904.retailrocket_data.events_cleaned`;