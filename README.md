# University Placement Management System (DBMS Project)

A relational database system designed to centralize and manage the entire university
placement process — student records, company profiles, placement drives, job roles,
interview rounds, offer letters, and analytics — replacing scattered spreadsheets and
manual tracking with a single, normalized, secure source of truth.

> Built as a database design project. Frontend/UI is not yet implemented — this repo
> currently focuses on schema design, normalization, and query logic.


## Project Highlights
- **23 normalized relational tables** (BCNF) covering students, companies, drives,
  applications, selection rounds, offer letters, mentors, training, and alumni.
- **Full SRS** following IEEE 830-1998 structure — requirements gathered through
  background research, stakeholder interviews, and a 40-response student/company/
  placement-cell questionnaire.
- **Role-based access design** for Students, Placement Cell, Faculty Coordinators,
  Recruiters, and Alumni.
- **35+ SQL queries** ranging from simple filters to multi-join reports, CTEs, window
  functions (`RANK`, `ROW_NUMBER`), and aggregate analytics (skill-gap analysis,
  branch-wise placement rate, CPI-vs-package correlation).
- **Triggers, stored functions, and procedures** for eligibility validation, duplicate
  application prevention, automatic alumni conversion, and drive status updates.

## Tech Stack
- **Database**: PostgreSQL
- **Design**: ER modeling → BCNF normalization → DDL implementation

## Repository Structure
```
placement-management-system/
├── README.md
├── docs/
│   ├── SRS.pdf                     # Full Software Requirements Specification
│   ├── ER_diagram.png              # Conceptual ER diagram
│   ├── ER_diagram_normalized.png   # Final ER diagram after normalization
│   └── normalization_notes.md      # Table-by-table BCNF justification
└── sql/
    ├── 01_schema.sql               # All CREATE TABLE statements
    ├── 02_triggers.sql             # Trigger functions
    ├── 03_functions_and_procedures.sql
    └── 04_queries.sql              # 35+ analytical queries
```

## Problem It Solves
Most university placement offices manage data through spreadsheets, emails, and paper
records — leading to data redundancy, inconsistent records, slow reporting, weak access
control, and risk of data loss during crashes. This project addresses each of these
through normalization, role-based access control, transaction-safe design, and
structured reporting (built with NAAC/NIRF accreditation reporting needs in mind).

## Status
- [x] Requirements gathering (interviews, questionnaire, background research)
- [x] ER modeling and normalization (BCNF)
- [x] DDL schema design
- [x] Triggers, functions, procedures
- [x] Analytical queries
- [ ] Schema validation / runnable end-to-end (in progress)
- [ ] Sample data set
- [ ] Frontend / UI

## Contributors
- Trisha Godhasara (202403046)
- Yashvi Pachani (202403062)


---
*This project was developed as part of a DBMS coursework, grounded in real interviews
with placement cell staff and a student/company survey (40+ responses).*
