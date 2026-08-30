# Project Documentation: International Cohort Risk Segmentation

Full technical walkthrough of the analysis behind [README.md](README.md): research question, schema design, the SQL technique tour, and the business-intelligence narrative built on top of it.

## Table of contents

- [Research question](#research-question)
- [Database schema](#database-schema)
- [How to run](#how-to-run)
- [Methodology](#methodology)
- [SQL techniques demonstrated](#sql-techniques-demonstrated)
- [Strategic recommendations](#strategic-recommendations)

---

## Research question

**How do international student cohorts cluster by risk profile when segmented by stay duration, demographic factors, and mental health indicators?**

Sub-questions:

- Which stay-duration cohorts exhibit highest depression and anxiety risk?
- How does social connectedness interact with stay duration in predicting isolation?
- What are the optimal demographic and temporal patterns for targeted mental health interventions?
- How do regional and classification factors modulate risk stratification?

---

## Database schema

```text
┌─────────────────────────────────────────────────────────────────┐
│                          student_db                             │
├─────────────────────────────────────────────────────────────────┤
│  students (core fact table)                                     │
│  ├─ id            INT PK AUTO_INCREMENT                         │
│  ├─ inter_dom     VARCHAR(10) NOT NULL  [Inter | Dom]           │
│  ├─ region        VARCHAR(50)           [SEA|EA|SA|JAP|Others]  │
│  ├─ stay          INT NOT NULL          [1–10 years]            │
│  ├─ todep         DECIMAL(5,2) NOT NULL [PHQ-9: 0–50]           │
│  ├─ tosc          DECIMAL(5,2) NOT NULL [SCS:   0–100]          │
│  ├─ toas          DECIMAL(5,2) NOT NULL [ASISS: 0–100]          │
│  ├─ created_at    TIMESTAMP                                     │
│  └─ updated_at    TIMESTAMP                                     │
│                                                                 │
│  INDEX: idx_inter_dom, idx_stay, idx_region                     │
│  CHECK: ranges validated for all score columns                  │
│                                                                 │
│  regions (reference)                  assessments (reference)   │
│  ├─ region_id PK                      ├─ assessment_id PK       │
│  ├─ region_name UNIQUE                ├─ assessment_name        │
│  ├─ region_code                       ├─ assessment_code        │
│  └─ description                       ├─ min_score / max_score  │
│                                       └─ description            │
│  student_classifications (reference)                            │
│  ├─ classification_id PK                                        │
│  ├─ classification_code UNIQUE                                  │
│  └─ classification_name                                         │
└─────────────────────────────────────────────────────────────────┘
```

Full schema with constraints, indexes, and reference data: [sql/schema.sql](sql/schema.sql)
Column definitions and scoring guides: [agent_docs/data_dictionary.md](agent_docs/data_dictionary.md)
SQL layer conventions (how `schema.sql` and `mysql_code.sql` relate): [sql/CLAUDE.md](sql/CLAUDE.md)

---

## How to run

```bash
pip install -r requirements.txt
mysql -u your_username -p < sql/schema.sql
jupyter notebook
# open advanced-student-wellbeing-sql-analysis.ipynb
```

The notebook is structured as follows:

| Section | Content |
| ------- | ------- |
| **1. Setup** | Database connection, library imports |
| **2. Data import** | CSV → MySQL ETL with validation |
| **3. Data quality** | NULL checks, range validation, outlier detection |
| **4. Core analysis** | Stay duration segmentation, Inter vs. Dom comparison |
| **5. Advanced SQL** | Window functions, CTEs, ROLLUP/CUBE, statistical queries |
| **6. Business intelligence** | Risk factors, intervention windows, resource guidance |
| **7. Visualisation** | Trend charts, distribution plots, cohort comparisons |
| **8. Recommendations** | Actionable outputs for student services teams |

Key libraries: `mysql-connector-python`, `sqlalchemy`, `pandas`, `numpy`, `matplotlib`, `seaborn`, `scipy`, `scikit-learn` — see [requirements.txt](requirements.txt) for pinned versions.

---

## Methodology

### Analytical framework

1. **Segmentation** — Students grouped by stay duration (Short: 1–2 yrs, Medium: 3–4 yrs, Long: 5–10 yrs) and student type (International vs. Domestic).
2. **Outcome metrics** — Three validated psychological instruments: PHQ-9 (depression), Social Connectedness Scale (isolation/belonging), ASISS (anxiety sensitivity).
3. **Risk stratification** — CASE-based SQL scoring model categorises each student as Low/Moderate/High risk across all three dimensions.
4. **Trend analysis** — Window functions (`LAG`, `LEAD`) compute year-over-year change in wellbeing scores across stay-duration cohorts.
5. **Regional analysis** — `ROLLUP` aggregations surface cross-cultural differences across SEA, EA, SA, JAP, and Other cohorts.

### Data quality controls

- CHECK constraints on all score columns enforce valid ranges at insert time
- Validation queries flag `NULL` values and out-of-range records
- Outlier detection applied prior to aggregate analysis

---

## SQL techniques demonstrated

### Database design

- Third Normal Form (3NF) normalisation
- InnoDB engine with referential integrity
- CHECK constraints for data validation
- Composite and single-column indexing strategy

### Analytical SQL (24 queries)

| Category | Techniques |
| -------- | ---------- |
| **Window functions** | `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `LAG()`, `LEAD()`, running totals with `SUM() OVER()` |
| **CTEs** | Multi-level `WITH` clauses; `WITH RECURSIVE` to generate a bounded stay-year ladder and expose coverage gaps |
| **OLAP** | `GROUP BY ... WITH ROLLUP` for hierarchical subtotals; a `UNION ALL`-built CUBE-equivalent for full cross-tabulation (MySQL has no native `CUBE`) |
| **Statistical** | `AVG()`, `STDDEV()`, `VARIANCE()`; median/quartiles via `ROW_NUMBER()`/`COUNT() OVER()` (MySQL has no `PERCENTILE_CONT`) |
| **Risk scoring** | `CASE`-based risk stratification (Low/Medium/High risk flags) |
| **Segmentation** | Stay-duration buckets, regional cohorts, classification comparisons |
| **Subqueries** | Correlated subqueries, `EXISTS`, `IN` with nested selects |

All queries live in [sql/mysql_code.sql](sql/mysql_code.sql) as a flat, sequential log (`-- Query N` blocks) mirroring the order they run in the notebook.

**A note on MySQL's OLAP/statistical gaps:** the standard `GROUP BY CUBE(...)` and `PERCENTILE_CONT`/`PERCENTILE_DISC` exist on Postgres, Oracle, and SQL Server but not on MySQL, which implements only `ROLLUP` and has no ordered-set aggregates. Sections 5.6 and 5.7 (below) build both by hand — a `UNION ALL` of every grouping-column combination for the cube, and a `ROW_NUMBER()`/`COUNT() OVER()` rank-matching trick for percentiles/median — rather than skipping the techniques or silently downgrading the documentation's claims about them.

#### Example — Risk stratification query

```sql
WITH risk_flags AS (
    SELECT
        id, inter_dom, region, stay, todep, tosc, toas,
        CASE
            WHEN todep > 20 THEN 'High Risk - Depression'
            WHEN toas  > 75 THEN 'High Risk - Anxiety'
            WHEN tosc  < 25 THEN 'High Risk - Isolation'
            ELSE 'Moderate / Low Risk'
        END AS risk_category
    FROM students
    WHERE inter_dom = 'Inter'
)
SELECT
    risk_category,
    COUNT(*)                      AS student_count,
    ROUND(AVG(stay), 1)           AS avg_stay_years,
    ROUND(AVG(todep), 2)          AS avg_depression,
    ROUND(AVG(tosc),  2)          AS avg_social_connectedness,
    ROUND(AVG(toas),  2)          AS avg_anxiety
FROM risk_flags
GROUP BY risk_category
ORDER BY student_count DESC;
```

#### Example — Stay duration trend with window function

```sql
SELECT
    stay,
    COUNT(*)                                          AS cohort_size,
    ROUND(AVG(todep), 2)                              AS avg_depression,
    ROUND(AVG(tosc),  2)                              AS avg_social_connectedness,
    ROUND(AVG(toas),  2)                              AS avg_anxiety,
    ROUND(AVG(todep) - LAG(AVG(todep)) OVER (ORDER BY stay), 2)
                                                      AS depression_change_yoy,
    ROUND(AVG(toas)  - LAG(AVG(toas))  OVER (ORDER BY stay), 2)
                                                      AS anxiety_change_yoy
FROM students
WHERE inter_dom = 'Inter'
GROUP BY stay
ORDER BY stay;
```

#### Example — Regional ROLLUP

```sql
SELECT
    COALESCE(region, 'ALL REGIONS') AS region,
    COALESCE(inter_dom, 'ALL')       AS student_type,
    COUNT(*)                         AS total_students,
    ROUND(AVG(todep), 2)             AS avg_depression,
    ROUND(AVG(tosc),  2)             AS avg_social_connectedness,
    ROUND(AVG(toas),  2)             AS avg_anxiety
FROM students
GROUP BY ROLLUP(region, inter_dom)
ORDER BY region, inter_dom;
```

#### Example — Recursive CTE: stay-duration ladder & gap detection

```sql
WITH RECURSIVE stay_ladder AS (
    SELECT 1 AS stay_year
    UNION ALL
    SELECT stay_year + 1 FROM stay_ladder WHERE stay_year < 10
),
cohort_stats AS (
    SELECT stay, COUNT(*) AS n_students, ROUND(AVG(todep), 2) AS avg_depression
    FROM students
    WHERE inter_dom = 'Inter'
    GROUP BY stay
)
SELECT
    l.stay_year,
    COALESCE(c.n_students, 0) AS n_students,
    c.avg_depression,
    CASE WHEN c.n_students IS NULL THEN 'NO DATA - GAP YEAR' ELSE 'DATA PRESENT' END AS coverage_flag
FROM stay_ladder l
LEFT JOIN cohort_stats c ON c.stay = l.stay_year
ORDER BY l.stay_year;
```

Against this dataset, this surfaces stay-year 9 as a genuine coverage gap (zero students recorded) that a plain `GROUP BY stay` would have silently omitted.

#### Example — CUBE-equivalent via UNION ALL (MySQL has no native CUBE)

```sql
SELECT region, inter_dom, COUNT(*) AS n_students, ROUND(AVG(todep), 2) AS avg_depression
FROM students GROUP BY region, inter_dom

UNION ALL

SELECT region, 'ALL', COUNT(*), ROUND(AVG(todep), 2)
FROM students GROUP BY region

UNION ALL

SELECT 'ALL REGIONS', inter_dom, COUNT(*), ROUND(AVG(todep), 2)
FROM students GROUP BY inter_dom

UNION ALL

SELECT 'ALL REGIONS', 'ALL', COUNT(*), ROUND(AVG(todep), 2)
FROM students

ORDER BY region, inter_dom;
```

Four grain levels for two dimensions — every combination `CUBE(region, inter_dom)` would produce natively elsewhere, versus `ROLLUP`'s 3 (which never shows `inter_dom` alone without `region`).

#### Example — Median/quartiles via window functions (MySQL has no PERCENTILE_CONT)

```sql
WITH ranked AS (
    SELECT
        todep,
        ROW_NUMBER() OVER (ORDER BY todep) AS rn,
        COUNT(*) OVER () AS cnt
    FROM students
    WHERE inter_dom = 'Inter'
)
SELECT
    ROUND(AVG(CASE WHEN rn IN (FLOOR((cnt+1)/2), CEIL((cnt+1)/2)) THEN todep END), 2) AS median_depression
FROM ranked;
```

`ROW_NUMBER()` ranks each value within the cohort; averaging the value(s) at the rank nearest `(n+1)/2` reproduces `PERCENTILE_CONT(0.5)`'s result without the function existing.

---

## Strategic recommendations

Based on the SQL analysis, three evidence-based recommendations emerge:

| Priority | Recommendation | Timing |
| -------- | -------------- | ------ |
| **1 — Immediate** | Launch a structured peer-support and mentorship programme targeting new international students in months 1–12 | 0–3 months |
| **2 — Short-term** | Establish regular wellbeing check-ins (PHQ-9/SCS screening) at enrolment, 3 months, and 6 months | 0–6 months |
| **3 — Strategic** | Develop a regional cohort model — tailor support resources by region (SEA, EA, SA) given differing cultural adaptation patterns | 6–12 months |

---

*Back to [README.md](README.md) for the quick-start summary and headline findings.*
