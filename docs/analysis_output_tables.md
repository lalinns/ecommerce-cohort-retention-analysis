# Analysis Output Tables
This document summarizes the final result tables created to support the reporting views in the retention analysis. These tables store aggregated analytical outputs used for interpretation, visualizations, or README reporting.

## 1. `overall_exactday_retention` table
An aggregated retention summary showing overall exact-day any-event retention at D1, D7, D14, and D30. Each checkpoint is calculated using only **mature users** who have enough observable time in the dataset.

- Type: Final analysis output table
- Grain: One row per retention checkpoint
- Source tables: `events_cleaned` and `visitor_first_seen`

| Column name | Type | Description |
|---|---|---|
| `checkpoint_order` | INTEGER | Numeric sort key used to display the checkpoints in chronological order: D1, D7, D14, and D30. |
| `checkpoint` | STRING | Retention checkpoint label, such as `D1`, `D7`, `D14`, or `D30`. |
| `mature_users` | INTEGER | Number of users with enough observation time in the dataset to be included in the denominator for that checkpoint. |
| `retained_users` | INTEGER | Number of mature users who had at least one event on the exact checkpoint day. |
| `retention_rate` | FLOAT | Exact-day retention rate, calculated as `retained_users / mature_users`. |

## 2. `weekly_cohort_retention` table
A cohort-level retention output that shows exact-day retention by weekly cohort and retention checkpoint.  Retention for each cohort-checkpoint combination is calculated using only **mature users** within that cohort who have enough observable time to be measured at that checkpoint.

- Type: Final analysis output table
- Grain: One row per weekly cohort and retention checkpoint
- Source tables: `events_cleaned` and `visitor_first_seen`

| Column name | Type | Description |
|---|---|---|
| `cohort_week` | DATE | Weekly cohort assigned from each user’s `first_seen` date, represented as the cohort week start date. |
| `checkpoint_order` | INTEGER | Numeric sort key used to display retention checkpoints in chronological order. |
| `checkpoint` | STRING | Retention checkpoint label, such as `D1`, `D7`, `D14`, or `D30`. |
| `cohort_users` | INTEGER | Total number of users assigned to that weekly cohort before checkpoint-specific maturity filtering. |
| `mature_users` | INTEGER | Number of users in the cohort with enough observation time to be included in the denominator for that checkpoint. |
| `retained_users` | INTEGER | Number of mature users in the cohort who had at least one event on the exact checkpoint day. |
| `retention_rate` | FLOAT | Exact-day retention rate for that cohort and checkpoint, calculated as `retained_users / mature_users`. |

## 3. `segmented_retention_data` table
An aggregated segmented-retention output comparing later exact-day retention across early browsing-breadth user groups. Each checkpoint-specific retention rate is calculated using only **mature users within that segment** who have enough observable time to be measured at that checkpoint.

- Type: Final analysis output table
- Grain: One row per browsing-breadth segment and retention checkpoint, or one row per segment with separate retention columns depending on how you materialized it
- Source tables: `events_cleaned` and `visitor_first_seen`

| Column name | Type | Description |
|---|---|---|
| `segment` | STRING | Early browsing-breadth segment based on distinct items interacted with in the first 3 days after `first_seen`, such as `1_item`, `2_3_items`, or `4plus_items`. |
| `D1_retention` | FLOAT | Exact-day D1 retention rate for mature users in that segment. |
| `D7_retention` | FLOAT | Exact-day D7 retention rate for mature users in that segment. |
| `D14_retention` | FLOAT | Exact-day D14 retention rate for mature users in that segment. |
| `D30_retention` | FLOAT | Exact-day D30 retention rate for mature users in that segment. |