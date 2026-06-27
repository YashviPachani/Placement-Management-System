# Normalization Notes

All 23 tables in this schema are normalized to **BCNF (Boyce-Codd Normal Form)** —
every determinant is a candidate key, eliminating redundancy and update anomalies.

## Core Entity Tables

| Table | Primary Key | Candidate Keys | Why BCNF |
|---|---|---|---|
| Student | S_ID | S_ID, Email_ID | All attributes depend only on S_ID, no transitive dependencies |
| Company | C_ID | C_ID, Email | All attributes depend only on C_ID |
| Drive | Drive_ID | Drive_ID | Single key, all attributes directly dependent |
| Job_Role | Job_Role_ID | Job_Role_ID | FKs (C_ID, Drive_ID) reference other PKs directly |
| Mentors | Mentor_ID | Mentor_ID | Simple entity, direct dependency |
| Training | Training_ID | Training_ID | All attributes dependent on Training_ID only |

## Dependent / Weak Entity Tables

| Table | Primary Key | Notes |
|---|---|---|
| Student_Phone | S_ID | Existence-dependent on Student; avoids repeating phone columns on Student itself |
| Alumni | S_ID | Specific to graduated students; kept separate to avoid nulls on active students |
| Placement_Coordinators | PC_ID | Coordinator role kept distinct from base Student attributes |
| Drive_log | Drive_ID | Additional drive metadata, 1:1 with Drive |
| Drive_Eligibility | (Drive_ID, Batch_Eligible) | Multi-valued "eligible batches" properly decomposed instead of repeating groups |

## Relationship (Many-to-Many) Tables

| Table | Primary Key | Resolves M:N Between |
|---|---|---|
| registers | Register_ID | Student ↔ Drive |
| Application | Application_ID | registers ↔ Job_Role |
| Student_Round_Result | Result_ID | Application ↔ Selection_Round |
| Company_Assigned | (C_ID, PC_ID) | Company ↔ Placement_Coordinators |
| Mentor_Student | (Mentor_ID, S_ID) | Mentors ↔ Student |
| Student_Training | (S_ID, Training_ID) | Student ↔ Training |

## Multi-valued Attribute Tables

These exist because a Job_Role can require multiple skills, support multiple
locations, and have different CPI cutoffs per branch — storing these as
comma-separated values in Job_Role would violate 1NF.

| Table | Primary Key |
|---|---|
| Job_Role_Academic_Eligibility | (Job_Role_ID, Branch_name) |
| Job_Role_Skill_Requirement | (Job_Role_ID, Skill_Name) |
| Job_Role_Location | (Job_Role_ID, Location) |

## Why this matters for the placement use case

- **No redundancy**: A company's name/website is stored once in `Company`, not
  repeated across every `Job_Role` row.
- **Update anomaly prevention**: Updating a student's CPI updates one row in
  `Student`; it doesn't need to cascade through application or resume records.
- **Insertion anomaly prevention**: A new job role's required skills can be added
  one at a time in `Job_Role_Skill_Requirement` without needing to know all other
  job-role attributes first.
- **Deletion anomaly prevention**: Deleting a `Drive` cascades cleanly to its
  `Job_Role`s and `Drive_Eligibility` rows via `ON DELETE CASCADE`, without leaving
  orphaned data elsewhere.
