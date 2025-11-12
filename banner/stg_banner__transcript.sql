{{ 
    config(
        materialized='view',
        tags=['staging', 'banner', 'transcript', 'academic']
    )
}}

/*
Purpose: Student transcript course work (completed courses with grades)
Source: SHRTCKN (Student Transcript)
Grain: One row per student per course per term
Key: SHRTCKN_PIDM + SHRTCKN_TERM_CODE + SHRTCKN_SEQ_NO
*/

with source as (
    select * from {{ source('banner', 'shrtckn') }}
),

renamed as (
    select 
        -- Primary Keys
        shrtckn_pidm as student_pidm,
        shrtckn_term_code as term_code,
        shrtckn_seq_no as sequence_number,
        
        -- Course Information
        shrtckn_subj_code as subject_code,
        shrtckn_crse_numb as course_number,
        shrtckn_crse_title as course_title,
        
        -- Credit Hours
        shrtckn_credit_hours as credit_hours,
        shrtckn_bill_hours as billing_hours,
        shrtckn_cont_hours as contact_hours,
        shrtckn_gpa_hours as gpa_hours,
        shrtckn_quality_points as quality_points,
        
        -- Grade Information
        shrtckn_grde_code as grade_code,
        cast(shrtckn_grde_date as date) as grade_date,
        shrtckn_gmod_code as grading_mode_code,
        
        -- Course Level
        shrtckn_levl_code as course_level_code,
        
        -- Campus/College/Department
        shrtckn_camp_code as campus_code,
        shrtckn_coll_code as college_code,
        shrtckn_dept_code as department_code,
        
        -- Schedule Type
        shrtckn_schd_code as schedule_type_code,
        
        -- Repeat Course
        shrtckn_rept_code as repeat_course_code,
        
        -- CRN (Course Reference Number)
        shrtckn_crn as course_reference_number,
        
        -- CEU (Continuing Education Units)
        shrtckn_ceu as continuing_education_units,
        
        -- Attempted Hours (State Reporting)
        shrtckn_atts_code as attempt_status_code,
        
        -- Transfer/Test Credit
        shrtckn_trans_recv_ind as is_transfer_received,
        shrtckn_test_score as test_score,
        
        -- Section Number
        shrtckn_seq_crse as course_sequence,
        
        -- Part of Term
        shrtckn_ptrm_code as part_of_term_code,
        
        -- Attendance
        cast(shrtckn_last_attend_date as date) as last_attendance_date,
        
        -- System Fields
        shrtckn_activity_date as activity_date,
        shrtckn_user_id as last_updated_by,
        shrtckn_data_origin as data_origin,
        shrtckn_vpdi_code as vpdi_code,
        
        -- Metadata
        {{ add_source_metadata('banner', 'shrtckn') }}
        
    from source
    where shrtckn_pidm is not null
      and shrtckn_term_code is not null
      and shrtckn_seq_no is not null
)

select * from renamed
