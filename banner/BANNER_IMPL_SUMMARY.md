# Banner to dbt Implementation Summary

## ✅ What I've Created

### 1. **Schema Extraction Tool**
📄 [banner_schema_extraction.sql](computer:///mnt/user-data/outputs/banner_schema_extraction.sql)

SQL script you can run against your Banner Oracle database to extract:
- Complete table column definitions
- Primary keys
- Foreign keys
- Table comments
- Row counts
- Sample data

**How to use:**
1. Open in SQL*Plus or SQL Developer
2. Update schema owner (line 47): `WHERE atc.owner = 'SATURN'`
3. Run the queries
4. Export results to compare with the standard models

### 2. **Banner Staging Models** (5 core tables)

| File | Banner Table | Purpose |
|------|--------------|---------|
| stg_banner__person_identity.sql | SPRIDEN | Person master (ID and name) |
| stg_banner__students.sql | SGBSTDN | Student demographics and status |
| stg_banner__registrations.sql | SFRSTCR | Current course registrations |
| stg_banner__transcript.sql | SHRTCKN | Historical coursework/grades |
| stg_banner__terms.sql | STVTERM | Term code reference table |

**Key Features:**
- Consistent naming conventions
- Proper data type casting
- Calculated fields (is_current, is_enrolled, etc.)
- Metadata tracking
- Boolean flags for easy filtering
- Ready for dbt compilation

### 3. **Source Configuration**
📄 [_banner_sources.yml](computer:///home/claude/models/deterge/staging/banner/_banner_sources.yml)

Complete source definitions with:
- Table descriptions
- Column descriptions
- Relationship tests
- Meta tags for governance
- 13 tables configured (5 core + 8 reference/additional)

### 4. **Comprehensive Guide**
📄 [BANNER_TO_DBT_GUIDE.md](computer:///mnt/user-data/outputs/BANNER_TO_DBT_GUIDE.md)

50+ page guide covering:
- Banner architecture concepts (PIDM, term codes, change indicators)
- Data extraction process
- Loading strategies (3 options)
- Common query patterns
- Testing strategies
- Gotchas and best practices
- Next steps

## 🎯 What Makes Banner Different

### Banner-Specific Concepts

**1. PIDM (Person IDentification Master)**
- Banner's internal ID for all persons
- ALL tables join via PIDM, not student ID
- SPRIDEN table maps PIDM ↔ Student ID

**2. Change Indicators**
- Historical tracking built into tables
- `SPRIDEN_CHANGE_IND = NULL` = current record
- Must filter for current records in most queries

**3. Term Codes**
- 6-digit format: `YYYYSS`
- Example: `202410` = Fall 2024
- Not chronological without parsing

**4. STV Tables**
- All reference/validation tables start with "STV"
- Must join for human-readable descriptions
- Examples: STVTERM, STVMAJR, STVDEGC

## 📊 Banner Data Flow

```
┌─────────────────┐
│ Banner Oracle   │  ← Your source system
│ (SATURN schema) │
└────────┬────────┘
         │
         ↓ (ETL: Fivetran, Airbyte, or custom)
         │
┌────────┴────────┐
│ Snowflake       │
│ BANNER_DEPOSIT  │  ← Raw Banner tables
└────────┬────────┘
         │
         ↓ (dbt staging models)
         │
┌────────┴────────┐
│ Deterge Staging │
│ stg_banner__*   │  ← Your staging models (what I created)
└────────┬────────┘
         │
         ↓ (dbt intermediate models - to build next)
         │
┌────────┴────────┐
│ int_students    │
│ int_enrollments │  ← Integrated models
│ int_transcripts │
└────────┬────────┘
         │
         ↓ (dbt distribute models)
         │
┌────────┴────────┐
│ dim_student     │
│ fact_enrollment │  ← Dimensional models for BI
└─────────────────┘
```

## 🔑 Key Banner Tables Reference

### Core Student Journey

```
SPRIDEN (Person ID)
    ↓
SGBSTDN (Student Demographics)
    ↓
SFRSTCR (Registration) → SHRTCKN (Transcript)
    ↓
SHRGPAC (GPA Calculation)
```

### Table Relationships

```sql
-- Getting student enrollments with names
SPRIDEN (person_id, pidm, names)
    ↓ join on PIDM
SGBSTDN (student info, major, level)
    ↓ join on PIDM
SFRSTCR (registrations, crn, term)
    ↓ join on term_code
STVTERM (term descriptions, dates)
```

## 🚀 Implementation Steps

### Phase 1: Setup (Week 1)
- [ ] Run schema extraction SQL
- [ ] Set up Snowflake target schema
- [ ] Configure ETL tool or data pipeline
- [ ] Load initial Banner data to Snowflake

### Phase 2: Staging Models (Week 2)
- [ ] Customize the 5 core models for your schema
- [ ] Create sources YAML
- [ ] Add additional staging models as needed
- [ ] Test with `dbt run` and `dbt test`

### Phase 3: Intermediate Models (Week 3-4)
- [ ] Create `int_students` (combine SPRIDEN + SGBSTDN)
- [ ] Create `int_enrollments` (SFRSTCR + SHRTCKN + reference tables)
- [ ] Create `int_student_terms` (term-level summaries)
- [ ] Apply business logic and calculations

### Phase 4: Dimensional Models (Week 5-6)
- [ ] Create `dim_student`
- [ ] Create `dim_course`
- [ ] Create `fact_enrollment`
- [ ] Apply governance (masking, RLS)

## 📦 Files Delivered

All files are in `/mnt/user-data/outputs/`:

1. **banner_schema_extraction.sql** - Run this first!
2. **BANNER_TO_DBT_GUIDE.md** - Complete reference guide
3. **banner_staging_models/** folder:
   - stg_banner__person_identity.sql
   - stg_banner__students.sql
   - stg_banner__registrations.sql
   - stg_banner__transcript.sql
   - stg_banner__terms.sql
   - _banner_sources.yml

## ⚠️ Important Notes

### Before You Start

1. **Schema Owner**: Banner tables are typically in 'SATURN' schema - verify with your DBA
2. **PIDM**: Everything joins via PIDM (internal ID), not student_id
3. **Change Indicators**: Always filter for NULL change indicators to get current records
4. **Data Volume**: SFRSTCR and SHRTCKN can be very large - consider incremental loads

### Custom Modifications Needed

Each Banner installation is customized. You'll likely need to:
- Add institution-specific columns
- Adjust for custom fields
- Add additional validation tables
- Handle institution-specific codes

### Next Steps

1. **Extract your schema** - Run the SQL script
2. **Compare with standard models** - See what's different
3. **Set up data loading** - Get Banner data into Snowflake
4. **Customize models** - Adjust for your schema
5. **Test thoroughly** - Validate against Banner queries
6. **Build intermediate layer** - Combine staging models

## 🎓 Key Learnings from Jenzabar → Banner

| Concept | Jenzabar | Banner |
|---------|----------|--------|
| **Primary Key** | Natural IDs (student_id) | PIDM (internal) |
| **History Tracking** | Separate history tables | Change indicators in same table |
| **Reference Tables** | Various prefixes | STV prefix |
| **Term Format** | Text codes | 6-digit numeric |
| **Table Naming** | Descriptive (prog_enr_rec) | Cryptic (SGBSTDN) |

## 💡 Pro Tips

1. **Always join through PIDM first**, then resolve to student_id
2. **Check change indicators** before assuming you have current data
3. **Use reference tables** - never hardcode Banner codes
4. **Term codes aren't chronological** - use STVTERM dates for sorting
5. **Test in Banner first** - validate dbt output against Banner queries

## 📞 Getting Help

If you run into issues:
1. Check the BANNER_TO_DBT_GUIDE.md (Part 8: Common Gotchas)
2. Compare your schema extraction with standard models
3. Verify PIDM relationships
4. Check for NULL vs missing data handling

## 🎉 You're Ready!

You now have:
✅ Schema extraction tool
✅ 5 core staging models
✅ Source configuration
✅ Comprehensive guide
✅ Implementation roadmap

**Next Step**: Run `banner_schema_extraction.sql` against your Banner database!
