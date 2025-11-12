{{ 
    config(
        materialized='view',
        tags=['staging', 'banner', 'registration', 'academic']
    )
}}

/*
Purpose: Student course registration/enrollment records
Source: SFRSTCR (Student Registration)
Grain: One row per student per course section per term
Key: SFRSTCR_PIDM + SFRSTCR_TERM_CODE + SFRSTCR_CRN
*/

with source as (
    select * from {{ source('banner', 'sfrstcr') }}
),

renamed as (
    select 
        -- Primary Keys
        sfrstcr_pidm as student_pidm,
        sfrstcr_term_code as term_code,
        sfrstcr_crn as course_reference_number,
        
        -- Course Information
        sfrstcr_crse_title as course_title,
        sfrstcr_crse_numb as course_number,
        sfrstcr_subj_code as subject_code,
        
        -- Registration Status
        sfrstcr_rsts_code as registration_status_code,
        cast(sfrstcr_rsts_date as date) as registration_status_date,
        
        -- Credit Hours
        sfrstcr_credit_hr as credit_hours,
        sfrstcr_bill_hr as billing_hours,
        sfrstcr_cont_hr as contact_hours,
        sfrstcr_gmod_code as grading_mode_code,
        
        -- Level
        sfrstcr_levl_code as course_level_code,
        
        -- Camp/College/Department
        sfrstcr_camp_code as campus_code,
        sfrstcr_coll_code as college_code,
        sfrstcr_dept_code as department_code,
        
        -- Schedule Type
        sfrstcr_schd_code as schedule_type_code,
        
        -- Registration Dates
        cast(sfrstcr_reg_date as date) as registration_date,
        cast(sfrstcr_add_date as date) as add_date,
        
        -- Grade Information
        sfrstcr_grde_code as grade_code,
        cast(sfrstcr_grde_date as date) as grade_date,
        
        -- Grade Source
        sfrstcr_grde_code_mid as midterm_grade_code,
        cast(sfrstcr_grde_date_mid as date) as midterm_grade_date,
        
        -- Registration Source
        sfrstcr_source_cde as registration_source_code,
        
        -- Attendance
        cast(sfrstcr_last_attend_date as date) as last_attendance_date,
        
        -- Drop/Withdraw
        cast(sfrstcr_drop_date as date) as drop_date,
        
        -- Repeat Course
        sfrstcr_rept_code as repeat_course_code,
        
        -- Link to Other Tables
        sfrstcr_ptrm_code as part_of_term_code,
        sfrstcr_program as program_code,
        
        -- Seats
        sfrstcr_seq_number as sequence_number,
        
        -- Voice Response Message
        sfrstcr_error_flag as has_error_flag,
        
        -- Waitlist
        sfrstcr_wl_pos as waitlist_position,
        
        -- CEU (Continuing Education Units)
        sfrstcr_ceu as continuing_education_units,
        
        -- Override/Permission
        sfrstcr_over_ride as has_override,
        
        -- Calculated Fields
        case 
            when sfrstcr_rsts_code in ('RE', 'RW') then true 
            else false 
        end as is_enrolled,
        
        case 
            when sfrstcr_drop_date is not null then true 
            else false 
        end as is_dropped,
        
        case 
            when sfrstcr_grde_code is not null then true 
            else false 
        end as has_grade,
        
        -- System Fields
        sfrstcr_activity_date as activity_date,
        sfrstcr_user_id as last_updated_by,
        sfrstcr_data_origin as data_origin,
        sfrstcr_vpdi_code as vpdi_code,
        
        -- Metadata
        {{ add_source_metadata('banner', 'sfrstcr') }}
        
    from source
    where sfrstcr_pidm is not null
      and sfrstcr_term_code is not null
      and sfrstcr_crn is not null
)

select * from renamed
