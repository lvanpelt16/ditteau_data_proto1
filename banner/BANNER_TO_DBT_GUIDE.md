# Banner to dbt Migration Guide

## Overview

This guide helps you extract your Banner schema and create dbt staging models for Ellucian Banner Student Information System.

## Part 1: Extract Your Banner Schema

### Step 1: Run the Schema Extraction SQL

1. Open the file: `banner_schema_extraction.sql`
2. Update the schema owner (typically 'SATURN'):
   ```sql
   WHERE atc.owner = 'SATURN'  -- Change to your Banner schema owner
   ```
3. Run in SQL*Plus, SQL Developer, or your Oracle client
4. Export results to CSV or Excel

### Step 2: Compare with Standard Models

The standard Banner models I've created are based on typical Banner implementations. Compare your actual schema with these models and adjust as needed.

## Part 2: Understanding Banner Tables

### Core Table Groups

#### **Person/Identity Tables**
- **SPRIDEN** - Person Identification (the master person table)
  - Key: `SPRIDEN_PIDM` (internal ID)
  - Links all Banner modules together via PIDM

#### **Student Information**
- **SGBSTDN** - Student Master (demographics, enrollment status)
  - Key: `SGBSTDN_PIDM + SGBSTDN_TERM_CODE_EFF`
  - One record per student per effective term
  
#### **Registration/Enrollment**
- **SFRSTCR** - Student Course Registration (active registrations)
  - Key: `SFRSTCR_PIDM + SFRSTCR_TERM_CODE + SFRSTCR_CRN`
  - One record per student per course section
  
- **SHRTCKN** - Student Transcript (completed courses with grades)
  - Key: `SHRTCKN_PIDM + SHRTCKN_TERM_CODE + SHRTCKN_SEQ_NO`
  - Historical academic record

#### **GPA Calculations**
- **SHRGPAC** - GPA Calculator
  - Stores term and cumulative GPA calculations
  
#### **Reference Tables (STV prefix)**
All reference tables start with "STV" (Status/Type Validation):
- **STVTERM** - Term codes
- **STVMAJR** - Major codes
- **STVDEGC** - Degree codes
- **STVLEVL** - Level codes (UG, GR, etc.)
- **STVSTST** - Student status codes

#### **Course Catalog**
- **SCBCRSE** - Course Master (catalog)
- **SSBSECT** - Section Master (offerings)

## Part 3: Key Banner Concepts

### PIDM (Person IDentification Master)
- **Internal ID** used throughout Banner
- All Banner tables join via PIDM, not student ID
- SPRIDEN.SPRIDEN_PIDM is the master reference

### Change Indicators
Many Banner tables track history with change indicators:
- **SPRIDEN_CHANGE_IND** - NULL = current record
- Always filter for NULL change_ind to get current records

### Term Codes
Banner uses 6-digit term codes:
- Format: `YYYYSS` (Year + Session)
- Example: `202410` = Fall 2024 (10 = Fall)
- Common suffixes: 10=Fall, 20=Spring, 30=Summer

### Status Codes
Banner uses cryptic codes everywhere:
- Always join to STV validation tables for descriptions
- Example: `SGBSTDN_STST_CODE` → join to `STVSTST` for description

## Part 4: Creating Your dbt Models

### File Structure

```
models/
└── deterge/
    └── staging/
        └── banner/
            ├── _banner_sources.yml      # Source definitions
            ├── stg_banner__person_identity.sql
            ├── stg_banner__students.sql
            ├── stg_banner__registrations.sql
            ├── stg_banner__transcript.sql
            ├── stg_banner__terms.sql
            └── ... (additional models)
```

### Naming Convention

**Pattern**: `stg_banner__<entity>.sql`

Examples:
- `stg_banner__students.sql` → SGBSTDN
- `stg_banner__registrations.sql` → SFRSTCR
- `stg_banner__transcript.sql` → SHRTCKN

### Common Patterns

#### Pattern 1: Get Current Records Only

```sql
-- For tables with change indicators
where spriden_change_ind is null

-- For tables with effective terms (get most recent)
qualify row_number() over (
    partition by sgbstdn_pidm 
    order by sgbstdn_term_code_eff desc
) = 1
```

#### Pattern 2: Join to Reference Tables

```sql
-- Always join STV tables for descriptions
left join {{ ref('stg_banner__term_codes') }} term
    on sfrstcr_term_code = term.term_code

left join {{ ref('stg_banner__majors') }} maj
    on sgbstdn_majr_code_1 = maj.major_code
```

#### Pattern 3: PIDM to Student ID Resolution

```sql
-- Always include PIDM to ID mapping
from {{ ref('stg_banner__registrations') }} reg
join {{ ref('stg_banner__person_identity') }} id
    on reg.student_pidm = id.person_pidm
    and id.is_current_record = true  -- NULL change_ind
```

## Part 5: Data Loading into Snowflake

### Option A: Direct Oracle → Snowflake

```sql
-- Use Snowflake's Oracle connector
CREATE OR REPLACE EXTERNAL STAGE banner_stage
URL = 'oracle://banner_prod'
CREDENTIALS = (ORACLE_USERNAME = '...' ORACLE_PASSWORD = '...');

-- Copy data
COPY INTO banner_deposit.sgbstdn
FROM @banner_stage/sgbstdn;
```

### Option B: ETL Tool (Fivetran, Airbyte, etc.)

Configure your ETL tool to:
1. Connect to Banner Oracle database
2. Select tables to sync
3. Load into `banner_deposit` schema in Snowflake
4. Schedule regular syncs

### Option C: CSV Export/Import

For one-time or ad-hoc loads:
1. Export from Banner Oracle to CSV
2. Upload to Snowflake stage
3. COPY INTO target tables

## Part 6: Common Banner Queries

### Get Current Student Information

```sql
select
    id.person_id as student_id,
    id.full_name,
    std.student_level_code,
    std.student_status_code,
    std.degree_code_1,
    std.expected_graduation_date
from {{ ref('stg_banner__students') }} std
join {{ ref('stg_banner__person_identity') }} id
    on std.student_pidm = id.person_pidm
    and id.is_current_record = true
-- Get most recent student record
qualify row_number() over (
    partition by std.student_pidm 
    order by std.effective_term_code desc
) = 1
```

### Get Student Course History

```sql
select
    id.person_id as student_id,
    trn.term_code,
    term.term_description,
    trn.subject_code,
    trn.course_number,
    trn.course_title,
    trn.grade_code,
    trn.credit_hours,
    trn.quality_points
from {{ ref('stg_banner__transcript') }} trn
join {{ ref('stg_banner__person_identity') }} id
    on trn.student_pidm = id.person_pidm
    and id.is_current_record = true
join {{ ref('stg_banner__terms') }} term
    on trn.term_code = term.term_code
order by trn.term_code, trn.sequence_number
```

### Get Current Term Enrollments

```sql
select
    id.person_id as student_id,
    reg.term_code,
    reg.course_reference_number as crn,
    reg.subject_code,
    reg.course_number,
    reg.course_title,
    reg.registration_status_code,
    reg.credit_hours,
    reg.grade_code
from {{ ref('stg_banner__registrations') }} reg
join {{ ref('stg_banner__person_identity') }} id
    on reg.student_pidm = id.person_pidm
    and id.is_current_record = true
where reg.is_enrolled = true
```

## Part 7: Testing Your Banner Models

### Essential Tests

```yaml
# models/deterge/staging/banner/_banner_models.yml
models:
  - name: stg_banner__students
    tests:
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - student_pidm
            - effective_term_code
    
    columns:
      - name: student_pidm
        tests:
          - not_null
          - relationships:
              to: ref('stg_banner__person_identity')
              field: person_pidm

  - name: stg_banner__registrations
    columns:
      - name: student_pidm
        tests:
          - not_null
          - relationships:
              to: ref('stg_banner__person_identity')
              field: person_pidm
      
      - name: term_code
        tests:
          - not_null
          - relationships:
              to: ref('stg_banner__terms')
              field: term_code
```

## Part 8: Common Gotchas

### 1. PIDM vs Student ID
❌ **Wrong**: Joining on student_id
✅ **Right**: Joining on PIDM, then resolving to student_id via SPRIDEN

### 2. Historical Records
❌ **Wrong**: Not filtering for current records
✅ **Right**: Always check change indicators and effective dates

### 3. Orphaned Records
- Not all PIDMs in SFRSTCR may exist in SPRIDEN
- Use LEFT JOINs when appropriate

### 4. NULL vs Empty String
- Banner uses NULL for missing data (not empty strings)
- Be careful with COALESCE and CASE statements

### 5. Term Code Formats
- Term codes are VARCHAR, not numeric
- Always use string comparison
- Watch for leading zeros

## Part 9: Next Steps

1. ✅ Extract your schema using the SQL script
2. ✅ Review the standard models I created
3. ✅ Customize models based on your schema differences
4. ✅ Create source configuration (_banner_sources.yml)
5. ✅ Set up Snowflake loading process
6. ✅ Create and test staging models
7. → Build intermediate models (int_students, int_enrollments, etc.)
8. → Create dimensional models for reporting

## Part 10: Additional Banner Tables to Consider

### Admissions
- **SARADAP** - Admissions Application
- **SARAPPD** - Application Decision

### Financial Aid
- **RCRAPP1** - FA Application
- **RPRATRM** - Award by Term

### Student Accounts
- **TBRACCD** - Accounts Detail
- **TBBESTU** - Student Balance

### Housing
- **SLRRASG** - Room Assignment


## Questions?

Common issues and solutions:
1. **Q**: How do I find my Banner schema owner?
   **A**: Usually 'SATURN', but ask your DBA

2. **Q**: Can I query Banner directly from dbt?
   **A**: Not recommended - load to Snowflake first

3. **Q**: How often should I sync Banner data?
   **A**: Daily is common, hourly for registration periods

4. **Q**: What about historical data?
   **A**: Banner maintains history in same tables (change indicators)
