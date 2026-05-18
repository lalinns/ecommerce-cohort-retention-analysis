-- Purpose:
-- Create a user-level anchor table for retention analysis.
-- -- first_seen = each visitor's earliest observed event timestamp in the cleaned events table.


--1/ Define anchor event, create a table
CREATE OR REPLACE TABLE `retailrocket-473904.retailrocket_data.visitor_first_seen` AS
SELECT visitorid, MIN(`timestamp`) AS first_seen
FROM `retailrocket-473904.retailrocket_data.events_cleaned`
GROUP BY visitorid

-- 2. Sanity check: confirm one anchor row per visitor
SELECT COUNT(*) AS n_rows_in_visitor_first_seen
    , COUNT(DISTINCT visitorid) AS n_distinct_visitors_in_visitor_first_seen
FROM `retailrocket-473904.retailrocket_data.visitor_first_seen`;

-- 3. Sanity check: confirm all visitors from events_cleaned are represented
SELECT COUNT(DISTINCT e.visitorid) AS n_distinct_visitors_in_events_cleaned
    , COUNT(DISTINCT f.visitorid) AS n_visitors_with_first_seen_anchor
FROM `retailrocket-473904.retailrocket_data.events_cleaned` AS e
LEFT JOIN `retailrocket-473904.retailrocket_data.visitor_first_seen` AS f
    ON e.visitorid = f.visitorid;