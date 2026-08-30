# sql/CLAUDE.md

SQL layer coding standards for this repo. Read this before touching either file in this folder — they serve different jobs and are not interchangeable.

## Two files, two jobs

- **`schema.sql`** — the canonical, production-style DDL. `students` fact table with `NOT NULL`, `CHECK` range constraints, indexes (`idx_inter_dom`, `idx_stay`, `idx_region`), plus 3NF reference tables (`regions`, `student_classifications`, `assessments`) with seed data. Run this once to stand up `student_db`. This is the source of truth for constraints and indexing — if you need to know what's enforced at the database level, read this file, not the notebook.
- **`mysql_code.sql`** — a flat, sequential export of every query actually run against the database, in the order it was run (`-- Query N` blocks), starting with a bare `DROP TABLE`/unconstrained `CREATE TABLE students` (intentionally simpler than `schema.sql` — no constraints) followed by all 24 analytical queries. Treat it as a raw log/reference of the SQL behind the notebook, **not** a schema source of truth, and don't refactor it into separate per-topic files — its value is being a literal run-order record.

## When modifying analysis SQL

1. Change or add the query in `mysql_code.sql`, in a new numbered `-- Query N` block at the end.
2. Mirror the same query into the corresponding cell of `../advanced-student-wellbeing-sql-analysis.ipynb` — the notebook is what actually gets read as the portfolio piece, so the two must stay in sync.
3. If the change touches a constraint, index, or reference table, update `schema.sql` too and note the divergence from `mysql_code.sql`'s intentionally-unconstrained `CREATE TABLE`.

## Do not

- Do not treat `mysql_code.sql`'s unconstrained `CREATE TABLE students` as a bug — it mirrors what was actually run, on purpose.
- Do not split `mysql_code.sql` into multiple files — the flat, numbered, sequential format is the point.
- Do not add a query here without also mirroring it into the notebook, or the two will drift.
