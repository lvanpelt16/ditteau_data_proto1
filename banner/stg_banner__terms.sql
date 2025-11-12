{{ 
    config(
        materialized='view',
        tags=['staging', 'banner', 'reference', 'terms']
    )
}}

/*
Purpose: Term code reference/validation table
Source: STVTERM (Term Code Validation)
Grain: One row per term code
Key: STVTERM_CODE
*/

with source as (
    select * from {{ source('banner', 'stvterm') }}
),

renamed as (
    select 
        -- Primary Key
        stvterm_code as term_code,
        
        -- Term Description
        stvterm_desc as term_description,
        
        -- Term Dates
        cast(stvterm_start_date as date) as term_start_date,
        cast(stvterm_end_date as date) as term_end_date,
        
        -- Financial Aid Year
        stvterm_fa_proc_yr as financial_aid_process_year,
        
        -- Housing Dates
        cast(stvterm_housing_start_date as date) as housing_start_date,
        cast(stvterm_housing_end_date as date) as housing_end_date,
        
        -- Academic Year
        stvterm_acyr_code as academic_year_code,
        
        -- Term Type (Fall, Spring, Summer, etc.)
        stvterm_trmt_code as term_type_code,
        
        -- System Requirement Flag
        stvterm_system_req_ind as is_system_required,
        
        -- Calculated Fields
        case 
            when current_date between stvterm_start_date and stvterm_end_date 
            then true 
            else false 
        end as is_current_term,
        
        case 
            when stvterm_start_date > current_date then true 
            else false 
        end as is_future_term,
        
        case 
            when stvterm_end_date < current_date then true 
            else false 
        end as is_past_term,
        
        -- Term Duration (days)
        datediff(day, stvterm_start_date, stvterm_end_date) as term_duration_days,
        
        -- System Fields
        stvterm_activity_date as activity_date,
        stvterm_user_id as last_updated_by,
        stvterm_data_origin as data_origin,
        stvterm_vpdi_code as vpdi_code,
        
        -- Metadata
        {{ add_source_metadata('banner', 'stvterm') }}
        
    from source
    where stvterm_code is not null
)

select * from renamed
