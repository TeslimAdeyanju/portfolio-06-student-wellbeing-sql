# International Student Wellbeing Analytics

> **Advanced SQL Portfolio** — Enterprise-level data analysis of international student mental health patterns using sophisticated database design and complex analytical queries.

![SQL](https://img.shields.io/badge/SQL-Advanced-blue?style=for-the-badge&logo=mysql)
![Python](https://img.shields.io/badge/Python-3.8+-green?style=for-the-badge&logo=python)
![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-orange?style=for-the-badge&logo=jupyter)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Status](https://img.shields.io/badge/Status-Portfolio_Ready-success?style=for-the-badge)

---

## Table of Contents

- [Project Overview](#project-overview)
- [Research Question](#research-question)
- [Dataset](#dataset)
- [Database Schema](#database-schema)
- [Key Findings](#key-findings)
- [SQL Techniques Demonstrated](#sql-techniques-demonstrated)
- [Project Structure](#project-structure)
- [Setup & Installation](#setup--installation)
- [How to Run](#how-to-run)
- [Methodology](#methodology)
- [Strategic Recommendations](#strategic-recommendations)
- [References](#references)
- [Contact](#contact)

---

## Project Overview

This project applies **enterprise-level SQL analytics** to a real-world mental health dataset collected from an international university. The analysis examines how length of stay influences depression, anxiety, and social connectedness among international student populations — providing data-driven insights that educational institutions can act on.

The project covers the full analytical lifecycle:

- Relational database design (3NF normalization)
- ETL pipeline from raw CSV to structured schema
- 25+ advanced SQL queries (CTEs, window functions, ROLLUP/CUBE, risk scoring)
- Statistical analysis and visualisation
- Business intelligence recommendations

---

## Research Question

**How does stay duration impact mental health outcomes among international student populations?**

Sub-questions explored:

- Which stay-duration cohort shows the highest risk of depression and anxiety?
- How does social connectedness evolve across years of enrollment?
- What is the optimal 6–12 month intervention window?
- How do regional and demographic factors interact with stay duration?

---

## Dataset

| Property | Detail |
| -------- | ------ |
| Source | International university student mental health survey |
| File | `students.csv` |
| Rows | Survey respondents (international + domestic students) |
| Format | CSV → MySQL (`student_db`) |

### Field Reference

| Column | Type | Range | Description |
| ------ | ---- | ----- | ----------- |
| `id` | INT | 1+ | Auto-incremented primary key |
| `inter_dom` | VARCHAR | `Inter` / `Dom` | Student classification (International or Domestic) |
| `region` | VARCHAR | SEA, EA, SA, JAP, Others | Geographic region of origin |
| `stay` | INT | 1–10 | Years of continuous enrollment |
| `todep` | DECIMAL | 0–50 | **PHQ-9** Depression Score |
| `tosc` | DECIMAL | 0–100 | **SCS** Social Connectedness Scale Score |
| `toas` | DECIMAL | 0–100 | **ASISS** Anxiety Scale Score |

#### Score Interpretation

**PHQ-9 (`todep`)** — depression severity:

- 0–4 → Minimal | 5–9 → Mild | 10–14 → Moderate | 15–19 → Moderately severe | 20+ → Severe

**Social Connectedness (`tosc`)** — sense of belonging:

- Higher scores → greater integration and social support

**Anxiety (`toas`)** — anxiety severity:

- 0–25 → Low | 26–50 → Moderate | 51–75 → High | 76–100 → Severe

---

## Database Schema

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

> Full schema with constraints, indexes, and reference data: [`schema.sql`](schema.sql)
> Column definitions and scoring guides: [`data_dictionary.md`](data_dictionary.md)

---

## Key Findings

| Finding | Metric | Impact |
| ------- | ------ | ------ |
| Shorter stays (1–2 yrs) → higher anxiety | **+34%** anxiety scores vs long-stay students | Critical early-intervention signal |
| Shorter stays → weaker social bonds | **−28%** social connectedness score | Isolation risk in first year |
| Highest-risk period identified | **First 6–12 months** of enrollment | Optimal intervention window |

### Stay Duration vs. Wellbeing (Summary)

```text
Stay (yrs) │  Avg Depression │  Avg Social Connectedness │  Avg Anxiety
───────────┼─────────────────┼───────────────────────────┼─────────────
    1       │     Highest     │          Lowest           │   Highest
    2–3     │     High        │          Low              │   High
    4–5     │     Moderate    │          Moderate         │   Moderate
    6+      │     Lower       │          Higher           │   Lower
```

> Visual output: [`trend_analysis.png`](trend_analysis.png)

---

## SQL Techniques Demonstrated

### Database Design

- Third Normal Form (3NF) normalization
- InnoDB engine with referential integrity
- CHECK constraints for data validation
- Composite and single-column indexing strategy

### Analytical SQL (25+ queries)

| Category | Techniques |
| -------- | ---------- |
| **Window Functions** | `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, `LAG()`, `LEAD()`, running totals with `SUM() OVER()` |
| **CTEs** | Multi-level `WITH` clauses, recursive CTEs for cohort chaining |
| **OLAP** | `GROUP BY ROLLUP`, `GROUP BY CUBE` for multi-dimensional aggregation |
| **Statistical** | `AVG()`, `STDDEV()`, `VARIANCE()`, percentile calculations |
| **Risk Scoring** | `CASE`-based risk stratification (Low / Medium / High risk flags) |
| **Segmentation** | Stay-duration buckets, regional cohorts, classification comparisons |
| **Subqueries** | Correlated subqueries, `EXISTS`, `IN` with nested selects |

#### Example — Risk Stratification Query

```sql
WITH risk_flags AS (
    SELECT
        id,
        inter_dom,
        region,
        stay,
        todep,
        tosc,
        toas,
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

#### Example — Stay Duration Trend with Window Function

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

---

## Project Structure

```text
3-Portfolio-Student-Wellbeing-SQL-Data-Analysis/
│
├── advanced-student-wellbeing-sql-analysis.ipynb   # Main portfolio notebook
│                                                   # 25+ SQL queries, visualisations,
│                                                   # BI insights, full narrative
│
├── schema.sql                                      # MySQL database creation script
│                                                   # Tables, indexes, constraints,
│                                                   # reference data inserts
│
├── students.csv                                    # Raw dataset (survey responses)
│
├── data_dictionary.md                              # Full column definitions,
│                                                   # scoring guides, validation rules
│
├── requirements.txt                                # Python dependencies
│
├── trend_analysis.png                              # Stay duration vs wellbeing chart
│
├── EXECUTION_CHECKLIST.md                          # Phase-by-phase task tracker
├── PROJECT_IMPLEMENTATION_GUIDE.md                 # Implementation roadmap
└── README.md                                       # This file
```

---

## Setup & Installation

### Prerequisites

- Python 3.8+
- MySQL 8.0+ (local or cloud instance)
- Jupyter Notebook / JupyterLab

### 1. Clone the Repository

```bash
git clone https://github.com/adeyanjuteslim/3-Portfolio-Student-Wellbeing-SQL-Data-Analysis.git
cd 3-Portfolio-Student-Wellbeing-SQL-Data-Analysis
```

### 2. Install Python Dependencies

```bash
pip install -r requirements.txt
```

Key libraries:

| Library | Version | Purpose |
| ------- | ------- | ------- |
| `mysql-connector-python` | 8.2.0 | MySQL database connection |
| `sqlalchemy` | 2.0.23 | ORM and query execution |
| `pandas` | 2.2.0 | Data manipulation |
| `numpy` | 1.26.2 | Numerical computation |
| `matplotlib` | 3.8.2 | Visualisation |
| `seaborn` | 0.13.0 | Statistical charts |
| `scipy` | 1.11.4 | Statistical tests |
| `scikit-learn` | 1.3.2 | Predictive modelling |

### 3. Configure the Database

```bash
# Connect to your MySQL instance and run the schema script
mysql -u your_username -p < schema.sql
```

This creates:

- `student_db` database
- `students` fact table with constraints and indexes
- `regions`, `student_classifications`, `assessments` reference tables
- Sample reference data inserts

### 4. Environment Variables (optional)

Create a `.env` file in the project root:

```env
DB_HOST=localhost
DB_PORT=3306
DB_NAME=student_db
DB_USER=your_username
DB_PASSWORD=your_password
```

The notebook uses `python-dotenv` to load these automatically.

---

## How to Run

```bash
# Launch Jupyter
jupyter notebook

# Open the main portfolio notebook
# advanced-student-wellbeing-sql-analysis.ipynb
```

The notebook is structured as follows:

| Section | Content |
| ------- | ------- |
| **1. Setup** | Database connection, library imports |
| **2. Data Import** | CSV → MySQL ETL with validation |
| **3. Data Quality** | NULL checks, range validation, outlier detection |
| **4. Core Analysis** | Stay duration segmentation, Int vs Dom comparison |
| **5. Advanced SQL** | Window functions, CTEs, ROLLUP/CUBE, statistical queries |
| **6. Business Intelligence** | Risk factors, intervention windows, resource guidance |
| **7. Visualisation** | Trend charts, distribution plots, cohort comparisons |
| **8. Recommendations** | Actionable outputs for student services teams |

---

## Methodology

### Analytical Framework

1. **Segmentation** — Students grouped by stay duration (Short: 1–2 yrs, Medium: 3–4 yrs, Long: 5–10 yrs) and student type (International vs Domestic).

2. **Outcome Metrics** — Three validated psychological instruments:

   - PHQ-9 (depression)
   - Social Connectedness Scale (isolation/belonging)
   - ASISS (anxiety sensitivity)

3. **Risk Stratification** — CASE-based SQL scoring model categorises each student as Low / Moderate / High risk across three dimensions (depression, anxiety, isolation).

4. **Trend Analysis** — Window functions (`LAG`, `LEAD`) compute year-over-year change in wellbeing scores across stay duration cohorts.

5. **Regional Analysis** — `ROLLUP` aggregations surface cross-cultural differences across SEA, EA, SA, JAP, and Other cohorts.

### Data Quality Controls

- CHECK constraints on all score columns enforce valid ranges at insert time
- Validation queries flag `NULL` values and out-of-range records
- Outlier detection applied prior to aggregate analysis

---

## Strategic Recommendations

Based on the SQL analysis, three evidence-based recommendations emerge:

| Priority | Recommendation | Timing |
| -------- | -------------- | ------ |
| **1 — Immediate** | Launch a structured peer-support and mentorship programme targeting new international students in months 1–12 | 0–3 months |
| **2 — Short-term** | Establish regular wellbeing check-ins (PHQ-9 / SCS screening) at enrolment, 3 months, and 6 months | 0–6 months |
| **3 — Strategic** | Develop a regional cohort model — tailor support resources by region (SEA, EA, SA) given differing cultural adaptation patterns | 6–12 months |

---

## References

- Kroenke K, Spitzer RL. *The PHQ-9: A new depression diagnostic and severity measure.* Psychiatric Annals. 2002;32(9):509–521.
- Lee RM, Draper M, Lee S. *Social connectedness, extraversion, and subjective well-being: Testing a mediation model.* Personality and Individual Differences. 2001;31(7):1033–1039.
- Taylor S, Zvolensky MJ. *Anxiety sensitivity: Theory, research, and treatment of the fear of anxiety.* Lawrence Erlbaum Associates; 2006.
- Twenge JM, et al. *Age, period, and cohort trends in mood disorder indicators and suicide-related outcomes.* Psychological Medicine. 2019.

---

## Contact

[![Email](https://img.shields.io/badge/Email-info@adeyanjuteslim.co.uk-red?style=for-the-badge&logo=gmail)](mailto:info@adeyanjuteslim.co.uk)
[![Website](https://img.shields.io/badge/Website-adeyanjuteslim.co.uk-blue?style=for-the-badge&logo=safari)](https://adeyanjuteslim.co.uk)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Teslim_Adeyanju-blue?style=for-the-badge&logo=linkedin)](https://www.linkedin.com/in/adeyanjuteslimuthman)

---

*Passionate about leveraging advanced SQL analytics to solve complex challenges in education and student wellbeing.*
