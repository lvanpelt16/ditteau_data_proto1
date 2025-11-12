{{ 
    config(
        materialized='view',
        tags=['staging', 'banner', 'student', 'core']
    )
}}

/*
Purpose: Student Master table from Banner
Source: SGBSTDN (Student Information - General Student)
Grain: One row per student (PIDM)
Key: SGBSTDN_PIDM
*/

with source as (
    select * from {{ source('banner', 'sgbstdn') }}
),

renamed as (
    select 
        -- Primary Key
        sgbstdn_pidm as student_pidm,
        
        -- Term Information
        sgbstdn_term_code_eff as effective_term_code,
        
        -- Student Classification
        sgbstdn_levl_code as student_level_code,
        sgbstdn_stst_code as student_status_code,
        sgbstdn_resd_code as residency_code,
        sgbstdn_styp_code as student_type_code,
        
        -- Academic Standing
        sgbstdn_astd_code_end_of_term as academic_standing_code,
        
        -- Enrollment Status
        sgbstdn_ests_code as enrollment_status_code,
        sgbstdn_rate_code as rate_code,
        
        -- Site/Campus
        sgbstdn_site_code as campus_site_code,
        
        -- Program/Degree
        sgbstdn_degc_code_1 as degree_code_1,
        sgbstdn_degc_code_2 as degree_code_2,
        sgbstdn_program_1 as program_code_1,
        sgbstdn_program_2 as program_code_2,
        
        -- Expected Graduation
        sgbstdn_exp_grad_date as expected_graduation_date,
        
        -- Admit Information  
        sgbstdn_admt_code as admit_type_code,
        sgbstdn_apst_code as application_status_code,
        cast(sgbstdn_apst_date as date) as application_status_date,
        
        -- Census Information
        sgbstdn_census_2_date as census_2_date,
        sgbstdn_census_2_seqno as census_2_sequence_number,
        
        -- GPA Hours
        sgbstdn_gpa_hours as gpa_hours,
        
        -- Cohort
        sgbstdn_chrt_code as cohort_code,
        
        -- Veteran Status
        sgbstdn_veteran_status as is_veteran,
        
        -- Admissions Information
        sgbstdn_admt_date as admit_date,
        sgbstdn_admr_code as admit_recruit_code,
        
        -- College Information
        sgbstdn_coll_code_1 as college_code_1,
        sgbstdn_coll_code_2 as college_code_2,
        
        -- Department
        sgbstdn_dept_code as department_code,
        
        -- Demographic Link
        sgbstdn_ethn_code as ethnicity_code,
        sgbstdn_citz_code as citizenship_code,
        
        -- Financial Aid
        sgbstdn_aid_year as financial_aid_year,
        
        -- System Fields
        sgbstdn_activity_date as activity_date,
        sgbstdn_user_id as last_updated_by,
        sgbstdn_data_origin as data_origin,
        sgbstdn_vpdi_code as vpdi_code,
        
        -- Metadata
        {{ add_source_metadata('banner', 'sgbstdn') }}
        
    from source
    where sgbstdn_pidm is not null
)

select * from renamed
