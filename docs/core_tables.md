# Core tables used
## 1. `events` table
The raw e-commerce event log. Each row records one user interaction with an item, such as viewing a product, adding a product to cart, or completing a transaction.
- Type: Source table
- Source table: Original Retailrocket dataset
- Grain: One row per logged e-commerce event
- Use case: Source table for event cleaning and all downstream retention analysis

| Column name | Type | Description |
|---|---|---|
| `timestamp` | INTEGER | Raw event timestamp stored as epoch milliseconds. |
| `visitorid` | INTEGER | Unique identifier for the visitor/user who generated the event. |
| `event` | STRING | Type of e-commerce interaction. Expected values are `view`, `addtocart`, and `transaction`. |
| `itemid` | INTEGER | Identifier of the item involved in the event. |
| `transactionid` | INTEGER | Identifier of the transaction. Populated only for `transaction` events; otherwise expected to be NULL. |

## 2. `events_cleaned` table
The cleaned event-level dataset used for the project’s retention analysis. It preserves the user-item interaction structure of the raw events table, while standardizing the timestamp field and removing duplicate event logs.

- Type: Cleaned analytical table
- Source table: events
- Grain: One row per deduplicated event
- Use case: Final event-level source for building retention cohorts, return flags, and browsing-breadth segmentation

| Column name | Type | Description |
|---|---|---|
| `timestamp` | TIMESTAMP | Event timestamp converted from raw epoch milliseconds into UTC `TIMESTAMP` format. |
| `visitorid` | INTEGER | Unique identifier for the visitor/user who generated the event. |
| `event` | STRING | Type of e-commerce interaction. Expected values are `view`, `addtocart`, and `transaction`. |
| `itemid` | INTEGER | Identifier of the item involved in the event. |
| `transactionid` | INTEGER | Identifier of the transaction. Populated only for `transaction` events; otherwise expected to be NULL. |

## 3. `visitor_first_seen` table
A user-level anchor table that stores the first observed event timestamp for each visitor in the available data window.

- Type: Derived analytical table
- Source table: events_cleaned
- Grain: One row per visitor
- Use case: Defines the proxy cohort anchor

| Column name | Type | Description |
|---|---|---|
| `visitorid` | INTEGER | Unique identifier for the visitor/user. |
| `first_seen` | TIMESTAMP | The visitor’s first observed event timestamp in the available data window. Used as the proxy cohort anchor for retention analysis. |