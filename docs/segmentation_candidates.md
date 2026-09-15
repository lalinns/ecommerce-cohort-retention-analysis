# Segmentation candidates

I screened several segmentation candidates before selecting **early browsing breadth** — the number of distinct items a user interacted with during the first 3 days after `first_seen` — as the primary segmentation lens for the retention analysis.

The selection followed this decision flow:

> **Why behavior? → Why early? → Which early behavior? → Does it create usable groups? → Do those groups differ in later retention?**

The screening can be summarized as two gates:

- **Gate 1 — Segmentation usability:** Does the candidate create sufficiently distinct groups for comparison?

- **Gate 2 — Retention relevance:** Do those groups show meaningful differences in later retention?

**Browsing breadth passed both the segmentation-usability check and the retention-relevance check**

## 1. Why behavioral segmentation?

The dataset has limited interpretable user attributes, while behavioral event data is directly usable for segmentation.

Event labels such as `view`, `addtocart`, and `transaction` are easy to interpret. By contrast, item-category context is stored as hashed IDs, which makes category-based segmentation harder to explain meaningfully in a portfolio analysis.

For that reason, I prioritized **behavioral segmentation** over item/category-based context segmentation.

## 2. Why use an early behavior window?

I defined segments using behavior observed in the **first 3 days after `first_seen`**, rather than using each user's full observed lifetime.

The goal was to test whether behavior visible early in the user lifecycle could identify groups with different later retention patterns. If an informative group can be identified early, it also creates a practical opportunity for product intervention before later retention checkpoints.

This means the segment-definition window comes before the later retention windows used for comparison.

## 3. Which early behaviors were screened?

I screened three early-behavior candidates:

1. **Early event-type behavior** — how many distinct event types a user generated.
2. **Early repeat frequency behavior** — how many active days a user had within the first 3 days.
3. **Early browsing breadth behavior** — how many distinct items a user interacted with within the first 3 days.

The first screening question was whether each candidate created sufficiently usable comparison groups.

### 3.1.  Early event-type behavior

Raw event-type behavior was tested using both Day-0 and first-3-day definition windows.

| Segment definition window | Dominant bucket | Share of users |
| --- | --- | ---: |
| Day-0 | `1 unique event type` | 97.81% |
| First 3 days | `1 unique event type` | 97.72% |

More than 97% of users fell into the shallowest event-type bucket, largely reflecting `view` behavior. The distribution was therefore too concentrated to provide enough user-level variation for the main segmented retention comparison.

I did not use raw event type as the primary segmentation lens.

### 3.2. Early repeat frequency behavior

Early repeat frequency was measured as the number of active days within the first 3 days after `first_seen`.

| Active days in first 3 days | Users | Share of users |
| ---: | ---: | ---: |
| 1 | 1,374,139 | 97.62% |
| 2 | 30,258 | 2.15% |
| 3 | 3,183 | 0.23% |

This candidate was similarly concentrated: 97.62% of users were active on only one day.

Although this is still a useful diagnostic signal about strong single-day behavior, it did not create sufficiently balanced groups for the primary segmented retention analysis.

### 3.3. Early browsing breadth behavior

Early browsing breadth was measured as the number of distinct items interacted with during the first 3 days after `first_seen`.

I initially screened four buckets — `1_item`, `2_items`, `3_items`, and `4plus_items` — then merged the two middle buckets into a more stable and interpretable three-group design.

| Segment | Users | Share of users |
| --- | ---: | ---: |
| `1_item` | 1,179,405 | 83.79% |
| `2_3_items` | 184,730 | 13.12% |
| `4plus_items` | 43,445 | 3.09% |

The distribution was still skewed, but it provided substantially more variation than the previous candidates and therefore a more usable basis for comparison.

## 4. Do the browsing-breadth groups differ in later retention?

After the distribution check, I ran a quick retention-separation check to see whether the browsing-breadth groups were also analytically relevant to the retention question.

Return behavior was measured cumulatively after the first 3-day segment-definition window.

| Segment | Users | Return rate, days 3–7 | Return rate, days 3–14 |
| --- | ---: | ---: | ---: |
| `1_item` | 1,179,405 | 1.89% | 3.01% |
| `2_3_items` | 184,730 | 4.43% | 6.47% |
| `4plus_items` | 43,445 | 10.18% | 13.79% |

The groups showed clear separation in later retention: users who interacted with more distinct items during the first 3 days also had higher subsequent return rates.

This does **not** establish that broader browsing causes higher retention. It shows that early browsing breadth is both:

- usable as a segmentation variable because it creates distinguishable groups, and
- relevant as a retention-analysis lens because those groups show meaningful differences in later return behavior.

For those reasons, **early browsing breadth was selected as the primary segmentation scope** for the project.

## 5. Summary screening

| Candidate | Gate 1: usable groups | Gate 2: later-retention separation | Decision |
| --- | --- | --- | --- |
| Raw event-type behavior | No — >97% in one bucket | Not pursued as primary lens | Reject as primary segmentation |
| Early repeat frequency | No — 97.62% in one bucket | Not pursued as primary lens | Reject as primary segmentation |
| Early browsing breadth | Yes — 83.79% / 13.12% / 3.09% | Yes — clear separation | Select as primary segmentation |

Rejected candidates are not necessarily useless.  The purpose of this screening was to choose one primary segmentation lens for the current retention analysis, not to prove that all other candidates lack business value.
