/*
Banner Schema Extraction Script
Purpose: Extract table and column definitions from your Banner Oracle database
Run this in SQL*Plus, SQL Developer, or your preferred Oracle client
Output: Table structures that you can use to build dbt models
*/

-- =============================================================================
-- 1. EXTRACT TABLE COLUMN DEFINITIONS
-- =============================================================================

SELECT 
    atc.table_name,
    atc.column_name,
    atc.column_id as ordinal_position,
    atc.data_type,
    atc.data_length,
    atc.data_precision,
    atc.data_scale,
    atc.nullable,
    acc.comments as column_comment,
    CASE 
        WHEN acc.constraint_type = 'P' THEN 'PRIMARY KEY'
        WHEN acc.constraint_type = 'U' THEN 'UNIQUE'
        WHEN acc.constraint_type = 'R' THEN 'FOREIGN KEY'
        ELSE NULL
    END as constraint_type
FROM all_tab_columns atc
LEFT JOIN all_col_comments acc 
    ON atc.owner = acc.owner 
    AND atc.table_name = acc.table_name 
    AND atc.column_name = acc.column_name
LEFT JOIN (
    SELECT 
        acc.owner,
        acc.table_name,
        acc.column_name,
        ac.constraint_type
    FROM all_cons_columns acc
    JOIN all_constraints ac 
        ON acc.constraint_name = ac.constraint_name
        AND acc.owner = ac.owner
) acc ON atc.owner = acc.owner 
    AND atc.table_name = acc.table_name 
    AND atc.column_name = acc.column_name
WHERE atc.owner = 'SATURN'  -- Change to your Banner schema owner
  AND atc.table_name IN (
    'SGBSTDN',    -- Student Master
    'SFRSTCR',    -- Student Course Registration
    'SHRTCKN',    -- Student Transcript
    'SHRGPAC',    -- Student GPA Calculator
    'STVTERM',    -- Term Code Table
    'SGRSACT',    -- Student Activities
    'SGRAATT',    -- Student Attributes
    'SORLCUR',    -- Student Curriculum
    'SORLFOS',    -- Student Field of Study
    'STVLEVL',    -- Level Code Table
    'STVSTST',    -- Student Status
    'STVMAJR',    -- Major Code Table
    'STVDEGC',    -- Degree Code Table
    'SSBSECT',    -- Section Master
    'SCBCRSE',    -- Course Master
    'SIRASGN',    -- Faculty Assignment
    'SPRIDEN'     -- Person Identification
  )
ORDER BY atc.table_name, atc.column_id;

-- =============================================================================
-- 2. EXTRACT PRIMARY KEYS
-- =============================================================================

SELECT 
    ac.table_name,
    acc.column_name,
    acc.position
FROM all_constraints ac
JOIN all_cons_columns acc 
    ON ac.constraint_name = acc.constraint_name
    AND ac.owner = acc.owner
WHERE ac.owner = 'SATURN'
  AND ac.constraint_type = 'P'
  AND ac.table_name IN (
    'SGBSTDN', 'SFRSTCR', 'SHRTCKN', 'SHRGPAC', 'STVTERM',
    'SGRSACT', 'SGRAATT', 'SORLCUR', 'SORLFOS', 'SSBSECT', 'SCBCRSE'
  )
ORDER BY ac.table_name, acc.position;

-- =============================================================================
-- 3. EXTRACT FOREIGN KEYS
-- =============================================================================

SELECT 
    ac.table_name as from_table,
    acc.column_name as from_column,
    ac_ref.table_name as to_table,
    acc_ref.column_name as to_column,
    ac.constraint_name
FROM all_constraints ac
JOIN all_cons_columns acc 
    ON ac.constraint_name = acc.constraint_name
    AND ac.owner = acc.owner
JOIN all_constraints ac_ref 
    ON ac.r_constraint_name = ac_ref.constraint_name
    AND ac.r_owner = ac_ref.owner
JOIN all_cons_columns acc_ref 
    ON ac_ref.constraint_name = acc_ref.constraint_name
    AND ac_ref.owner = acc_ref.owner
    AND acc.position = acc_ref.position
WHERE ac.owner = 'SATURN'
  AND ac.constraint_type = 'R'
  AND ac.table_name IN (
    'SGBSTDN', 'SFRSTCR', 'SHRTCKN', 'SHRGPAC', 'STVTERM',
    'SGRSACT', 'SGRAATT', 'SORLCUR', 'SORLFOS', 'SSBSECT', 'SCBCRSE'
  )
ORDER BY ac.table_name, ac.constraint_name;

-- =============================================================================
-- 4. EXTRACT TABLE COMMENTS
-- =============================================================================

SELECT 
    table_name,
    comments
FROM all_tab_comments
WHERE owner = 'SATURN'
  AND table_name IN (
    'SGBSTDN', 'SFRSTCR', 'SHRTCKN', 'SHRGPAC', 'STVTERM',
    'SGRSACT', 'SGRAATT', 'SORLCUR', 'SORLFOS', 'SSBSECT', 'SCBCRSE'
  )
ORDER BY table_name;

-- =============================================================================
-- 5. QUICK TABLE ROW COUNTS (to understand size)
-- =============================================================================

SELECT 'SGBSTDN' as table_name, COUNT(*) as row_count FROM SGBSTDN
UNION ALL
SELECT 'SFRSTCR', COUNT(*) FROM SFRSTCR
UNION ALL
SELECT 'SHRTCKN', COUNT(*) FROM SHRTCKN
UNION ALL
SELECT 'SHRGPAC', COUNT(*) FROM SHRGPAC
UNION ALL
SELECT 'STVTERM', COUNT(*) FROM STVTERM
UNION ALL
SELECT 'SSBSECT', COUNT(*) FROM SSBSECT
UNION ALL
SELECT 'SCBCRSE', COUNT(*) FROM SCBCRSE
UNION ALL
SELECT 'SPRIDEN', COUNT(*) FROM SPRIDEN;

-- =============================================================================
-- 6. SAMPLE DATA (to understand values)
-- =============================================================================

-- Student Master
SELECT * FROM SGBSTDN WHERE ROWNUM <= 5;

-- Term Codes
SELECT * FROM STVTERM WHERE ROWNUM <= 10 ORDER BY STVTERM_CODE DESC;

-- Course Registration
SELECT * FROM SFRSTCR WHERE ROWNUM <= 5;
