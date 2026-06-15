# Segmentation scope screening
After screening multiple candidates, I selected **early browsing breadth**, defined as distinct items interacted with in the first 3 days after `first_seen`, as the primary segmentation scope for this project.

The goal of this screening was not to prove that rejected candidates are useless. Instead, the goal was to choose one primary segmentation that best supports the project’s business question:

> How can we validate the concern around newly observed user retention and improve retention outcomes?

To choose the primary segmentation, I evaluated each candidate using the following criteria:
- alignment with the early-session retention question
- whether the segment can be defined before later retention checkpoints
- interpretability for a portfolio reader
- whether the distribution provides enough variation for comparison

A highly concentrated segment distribution does not automatically make a candidate invalid. For example, buyer-focused segmentation can still be business-important even if buyers are a small group. Buyer-focused retention is therefore saved as future work.

## 1. Choice of event-based behavior over item-based context

I first prioritized event-based behavioral segmentation over item-based context segmentation. In this dataset, event labels such as view, addtocart, and transaction are directly interpretable, while item category information is stored as hashed IDs and is therefore much harder to explain clearly in a portfolio analysis.

## 2. Raw event-type behavior was not suitable

I tested raw event-type behavior under two segment definition windows:
- Day-0
- First 3 days

| Candidate screened      | Segment definition window | Dominant bucket       | Share of users |
| ----------------------- | ------------------------- | --------------------- | -------------- |
| Raw event-type behavior | Day-0                     | `1 unique event type` | 97.81%         |
| Raw event-type behavior | First 3 days              | `1 unique event type` | 97.72%         |

Across all two timing choices, more than 97% of users consistently fell into the shallowest event-type bucket (`view`). This suggests that the raw event-type buckets were too concentrated to provide much user-level variation for the main comparison. 

Since this project focuses on early-session retention drop-off among newly observed users, **buyer-focused retention is saved for future work, which would answer a narrower follow-up question: whether purchasing users retain differently from non-purchasing users.**

## 3. Screening richer behavioral features

Since raw event-type segmentation was too weak, I next screened richer derived behavioral features within an early 3-day window.

### 3.1. Early repeat frequency candidate
The first candidate was repeat frequency, measured as the number of active days within the first 3 days after first_seen.

| active days in first 3 days | total users | % of total users in active day bucket |
|---:|---:|---:|
| 1 | 1,374,139 | 97.62% |
| 2 | 30,258 | 2.15% |
| 3 | 3,183 | 0.23% |

From the output, this candidate was also highly concentrated: about 97.6% of users fell into the 1 active day bucket. Because the candidate mostly separates one very large low-frequency group from very small higher-frequency groups, **I did not choose early repeat frequency as the primary segmentation.** It is still useful as a diagnostic signal showing strong single-touch behavior, but less useful as the main segmented retention lens.

### 3.2. Early browsing breadth candidate

The final candidate was browsing breadth, measured as the number of distinct items interacted with in the first 3 days after first_seen.

I initially screened this candidate using four buckets: 1_item, 2_items, 3_items, and 4plus_items. Since the middle buckets were relatively small and conceptually similar, I merged them into a more stable and interpretable three-bucket design: 1_item, 2_3_items, and 4plus_items.

| segment label | total users in segment | % of users in segment |
|---|---:|---:|
| `1_item` | 1,179,405 | 83.79% |
| `2_3_items` | 184,730 | 13.12% |
| `4plus_items` | 43,445 | 3.09% |

This candidate showed a more usable distribution than the previous options and provided a clearer basis for segmented analysis. More importantly, it aligns directly with the project’s business question.

After that, I ran a quick retention separation check to confirm that the segmentation was not only usable in distribution, but also analytically meaningful. In this check, return behavior is measured cumulatively after the first 3-day segment-definition window: any return during days 3–7 and any return during days 3–14 after first_seen.


| segment label | total users in segment | return rate in days 3–7 after first_seen | return rate in days 3–14 after first_seen |
|---|---:|---:|---:|
| `1_item` | 1,179,405 | 1.89% | 3.01% |
| `2_3_items` | 184,730 | 4.43% | 6.47% |
| `4plus_items` | 43,445 | 10.18% | 13.79% |

The results showed meaningful separation in later retention across the selected buckets: users who interacted with more distinct items early on showed higher later retention.
