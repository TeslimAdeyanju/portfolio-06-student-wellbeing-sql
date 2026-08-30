# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A SQL portfolio project analyzing international student mental health data. The research question: how does length of stay (1-10 years) affect depression (PHQ-9), anxiety (ASISS), and social connectedness (SCS) among international vs. domestic students. Everything flows from one CSV (`students.csv`) loaded into a single `students` table in MySQL. See [README.md](README.md) for headline findings and [PROJECT_DOCUMENTATION.md](PROJECT_DOCUMENTATION.md) for the full methodology and SQL technique tour.

## Commands

There is no build, lint, or test tooling — this is a data/SQL analysis project, not an application.

```bash
# Install Python dependencies
pip install -r requirements.txt

# Create the database, tables, constraints, and reference data
mysql -u your_username -p < sql/schema.sql

# Run the analysis
jupyter notebook
# then open advanced-student-wellbeing-sql-analysis.ipynb
```

Database credentials are read from a local `.env` (gitignored, loaded via `python-dotenv`): `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_NAME`, `DB_CHARSET`, `DB_TIMEZONE`.

To validate data quality directly in MySQL:

```sql
SELECT * FROM students
WHERE stay NOT BETWEEN 1 AND 10
   OR todep NOT BETWEEN 0 AND 50
   OR tosc NOT BETWEEN 0 AND 100
   OR toas NOT BETWEEN 0 AND 100;
```

## Project structure

```text
4-Advanced-SQL-Analytics-International-Cohort-Risk-Segmentation/
├── README.md                          ← Quick-start summary
├── PROJECT_DOCUMENTATION.md           ← Full methodology, SQL tour, BI narrative
├── CLAUDE.md                          ← This file
├── advanced-student-wellbeing-sql-analysis.ipynb   ← The portfolio deliverable
├── students.csv                       ← Raw survey dataset
├── requirements.txt
├── agent_docs/
│   └── data_dictionary.md             ← Field-level detail, score interpretation, validation rules
├── docs/images/
│   └── trend_analysis.png             ← Generated chart artifact, not a source file
└── sql/
    ├── CLAUDE.md                      ← SQL layer conventions — read before touching either file below
    ├── schema.sql                     ← Canonical DDL
    └── mysql_code.sql                 ← Flat, sequential query log
```

## Architecture

**Three SQL artifacts, three different jobs — don't confuse them:**

- `sql/schema.sql` — the canonical, production-style DDL: `students` fact table with `NOT NULL`, `CHECK` range constraints, indexes (`idx_inter_dom`, `idx_stay`, `idx_region`), plus 3NF reference tables (`regions`, `student_classifications`, `assessments`) with seed data. Run this once to stand up `student_db`.
- `sql/mysql_code.sql` — a flat, sequential export of every query actually run against the database in query order (`-- Query N` blocks), starting with a bare `DROP TABLE` / unconstrained `CREATE TABLE students` (no constraints — this is intentionally simpler than `schema.sql`) followed by all 24 analytical queries. Treat it as a raw log/reference of the SQL behind the notebook, not a schema source of truth. Full conventions for this folder: [sql/CLAUDE.md](sql/CLAUDE.md).
- `advanced-student-wellbeing-sql-analysis.ipynb` — the actual portfolio deliverable. Connects to MySQL via `sqlalchemy`/`mysql-connector-python`, runs the queries from `sql/mysql_code.sql` in the same order, and layers narrative, visualization (matplotlib/seaborn/plotly), and business-intelligence commentary on top. Structure: 1) Setup/connection, 2) CSV→MySQL import, 3) data quality checks, 4) core segmentation (stay-duration buckets, Inter vs Dom, risk stratification, regional patterns), 5) advanced SQL (window functions, CTEs, ROLLUP, recursive CTEs, CUBE-equivalent, percentile/median, stats), 6) BI translation (risk factors, intervention timing, resourcing, retention modeling), 7) visualization, 8) recommendations.

When modifying analysis SQL, the expected pattern is: change/add the query in `sql/mysql_code.sql` in its numbered `-- Query N` block, then mirror it into the corresponding notebook cell so the two stay in sync — the notebook is what actually gets read as the portfolio piece. Full detail: [sql/CLAUDE.md](sql/CLAUDE.md).

**Data model** (see `agent_docs/data_dictionary.md` for full field-level detail): a single wide table, one row per student —

- `inter_dom` (`Inter`/`Dom`) is the primary segmentation dimension throughout the analysis.
- `region` (SEA/EA/SA/JAP/Others) is the secondary, cross-cultural segmentation dimension.
- `stay` (1-10 years) is the independent variable the whole research question hinges on — most queries `GROUP BY stay` or bucket it into short/medium/long cohorts (1-2 / 3-4 / 5-10 yrs).
- `todep`, `tosc`, `toas` are the three outcome metrics (depression, social connectedness, anxiety) — risk-stratification queries key off fixed thresholds on these (e.g., `todep > 20`, `toas > 75`, `tosc < 25`).

`docs/images/trend_analysis.png` is a generated chart artifact referenced from `README.md`, not a source file — regenerate it from the notebook (cell saves to `docs/images/trend_analysis.png`) if the underlying trend queries change.
