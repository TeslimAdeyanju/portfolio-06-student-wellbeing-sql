-- ============================
-- Query 1
-- ============================
DROP TABLE IF EXISTS students

-- ============================
-- Query 2
-- ============================
CREATE TABLE students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    inter_dom VARCHAR(10),
    region VARCHAR(50),
    stay INT,
    todep DECIMAL(5,2),
    tosc DECIMAL(5,2),
    toas DECIMAL(5,2),
    INDEX idx_inter_dom (inter_dom),
    INDEX idx_stay (stay)
)

-- ============================
-- Query 3
-- ============================
-- FIRST NORMAL FORM (1NF): Eliminate repeating groups and ensure atomic values
-- Current students table is already in 1NF, but let's create an enhanced version

CREATE TABLE IF NOT EXISTS students_1nf (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    student_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    enrollment_date DATE NOT NULL,
    graduation_date DATE NULL,
    status ENUM('Active', 'Graduated', 'Withdrawn') DEFAULT 'Active',
    stay_duration_years INT NOT NULL,
    student_type ENUM('International', 'Domestic') NOT NULL,
    home_country VARCHAR(100) NOT NULL,
    program_name VARCHAR(150) NOT NULL,
    program_level ENUM('Undergraduate', 'Graduate', 'PhD') NOT NULL,
    faculty VARCHAR(100) NOT NULL,
    advisor_name VARCHAR(100) NOT NULL,
    advisor_email VARCHAR(150) NOT NULL,
    advisor_department VARCHAR(100) NOT NULL,
    phq9_score DECIMAL(4,2) NOT NULL CHECK (phq9_score >= 0 AND phq9_score <= 27),
    scs_score DECIMAL(4,2) NOT NULL CHECK (scs_score >= 8 AND scs_score <= 48),
    anxiety_score DECIMAL(4,2) NOT NULL CHECK (anxiety_score >= 0 AND anxiety_score <= 80),
    assessment_date DATE NOT NULL,
    assessment_semester VARCHAR(20) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Constraints
    INDEX idx_student_type (student_type),
    INDEX idx_stay_duration (stay_duration_years),
    INDEX idx_assessment_date (assessment_date),
    INDEX idx_program (program_name, program_level)
);

-- ============================
-- Query 4
-- ============================
-- Comprehensive Data Quality Assessment for Student Wellbeing Analysis
SELECT 
    'Data Completeness Analysis' as assessment_type,
    COUNT(*) as total_records,
    COUNT(CASE WHEN stay IS NOT NULL THEN 1 END) as stay_complete,
    COUNT(CASE WHEN todep IS NOT NULL THEN 1 END) as phq_complete,
    COUNT(CASE WHEN tosc IS NOT NULL THEN 1 END) as scs_complete,
    COUNT(CASE WHEN toas IS NOT NULL THEN 1 END) as anxiety_complete,
    COUNT(CASE WHEN inter_dom IS NOT NULL THEN 1 END) as status_complete,
    ROUND(
        (COUNT(CASE WHEN stay IS NOT NULL AND todep IS NOT NULL 
                    AND tosc IS NOT NULL AND toas IS NOT NULL 
                    AND inter_dom IS NOT NULL THEN 1 END) * 100.0 / COUNT(*)), 2
    ) as overall_completeness_pct
FROM students

UNION ALL

SELECT 
    'Data Range Validation' as assessment_type,
    COUNT(*) as total_records,
    COUNT(CASE WHEN stay BETWEEN 1 AND 10 THEN 1 END) as valid_stay_range,
    COUNT(CASE WHEN todep BETWEEN 0 AND 50 THEN 1 END) as valid_phq_range,
    COUNT(CASE WHEN tosc BETWEEN 0 AND 100 THEN 1 END) as valid_scs_range,
    COUNT(CASE WHEN toas BETWEEN 0 AND 100 THEN 1 END) as valid_anxiety_range,
    COUNT(CASE WHEN inter_dom IN ('Inter', 'Dom') THEN 1 END) as valid_status,
    ROUND(
        (COUNT(CASE WHEN stay BETWEEN 1 AND 10 AND todep BETWEEN 0 AND 50 
                    AND tosc BETWEEN 0 AND 100 AND toas BETWEEN 0 AND 100 
                    AND inter_dom IN ('Inter', 'Dom') THEN 1 END) * 100.0 / COUNT(*)), 2
    ) as overall_validity_pct
FROM students;

-- ============================
-- Query 5
-- ============================
-- Advanced Demographic Segmentation Analysis with Statistical Functions
WITH demographic_stats AS (
    SELECT 
        inter_dom as student_status,
        COUNT(*) as population_size,
        ROUND(AVG(todep), 2) as avg_depression_score,
        ROUND(AVG(tosc), 2) as avg_social_connectedness,
        ROUND(AVG(toas), 2) as avg_anxiety_score,
        ROUND(STDDEV(todep), 2) as stddev_depression,
        ROUND(STDDEV(tosc), 2) as stddev_social,
        ROUND(STDDEV(toas), 2) as stddev_anxiety,
        ROUND(MIN(todep), 2) as min_depression,
        ROUND(MAX(todep), 2) as max_depression,
        ROUND(MIN(tosc), 2) as min_social,
        ROUND(MAX(tosc), 2) as max_social,
        ROUND(MIN(toas), 2) as min_anxiety,
        ROUND(MAX(toas), 2) as max_anxiety
    FROM students 
    GROUP BY inter_dom
),

percentile_analysis AS (
    SELECT 
        inter_dom as student_status,
        ROUND(AVG(CASE WHEN depression_percentile <= 25 THEN todep END), 2) as q1_depression,
        ROUND(AVG(CASE WHEN depression_percentile >= 50 AND depression_percentile <= 50 THEN todep END), 2) as median_depression,
        ROUND(AVG(CASE WHEN depression_percentile >= 75 THEN todep END), 2) as q3_depression,
        ROUND(AVG(CASE WHEN social_percentile <= 25 THEN tosc END), 2) as q1_social,
        ROUND(AVG(CASE WHEN social_percentile >= 50 AND social_percentile <= 50 THEN tosc END), 2) as median_social,
        ROUND(AVG(CASE WHEN social_percentile >= 75 THEN tosc END), 2) as q3_social,
        ROUND(AVG(CASE WHEN anxiety_percentile <= 25 THEN toas END), 2) as q1_anxiety,
        ROUND(AVG(CASE WHEN anxiety_percentile >= 50 AND anxiety_percentile <= 50 THEN toas END), 2) as median_anxiety,
        ROUND(AVG(CASE WHEN anxiety_percentile >= 75 THEN toas END), 2) as q3_anxiety
    FROM (
        SELECT 
            inter_dom,
            todep,
            tosc,
            toas,
            PERCENT_RANK() OVER (PARTITION BY inter_dom ORDER BY todep) * 100 as depression_percentile,
            PERCENT_RANK() OVER (PARTITION BY inter_dom ORDER BY tosc) * 100 as social_percentile,
            PERCENT_RANK() OVER (PARTITION BY inter_dom ORDER BY toas) * 100 as anxiety_percentile
        FROM students
    ) ranked_data
    GROUP BY inter_dom)


SELECT 
    ds.student_status,
    ds.population_size,
    ROUND((ds.population_size * 100.0 / SUM(ds.population_size) OVER()), 2) as population_percentage,
    ds.avg_depression_score,
    pa.q1_depression,
    pa.median_depression,
    pa.q3_depression,
    ds.stddev_depression,
    ds.avg_social_connectedness,
    pa.q1_social,
    pa.median_social,
    pa.q3_social,
    ds.stddev_social,
    ds.avg_anxiety_score,
    pa.q1_anxiety,
    pa.median_anxiety,
    pa.q3_anxiety,
    ds.stddev_anxiety,
    -- Risk indicator flags
    CASE 
        WHEN ds.avg_depression_score > 15 THEN 'HIGH_RISK'
        WHEN ds.avg_depression_score > 10 THEN 'MODERATE_RISK'
        ELSE 'LOW_RISK'
    END as depression_risk_level,
    CASE 
        WHEN ds.avg_anxiety_score > 50 THEN 'HIGH_ANXIETY'
        WHEN ds.avg_anxiety_score > 35 THEN 'MODERATE_ANXIETY'
        ELSE 'LOW_ANXIETY'
    END as anxiety_risk_level
FROM demographic_stats  as ds
JOIN percentile_analysis as pa ON ds.student_status = pa.student_status
ORDER BY ds.population_size DESC;

-- ============================
-- Query 6
-- ============================
-- SECTION 4.1: Stay Duration Segmentation Analysis

-- CTE: duration_segments
WITH duration_segments AS (
    SELECT 
        CASE 
            WHEN stay BETWEEN 1 AND 2 THEN 'Short-stay (1-2yr)'
            WHEN stay BETWEEN 3 AND 4 THEN 'Medium-stay (3-4yr)'
            WHEN stay >= 5 THEN 'Long-stay (5+yr)'
        END as duration_segment,
        stay,
        COUNT(*) as student_count,
        COUNT(CASE WHEN inter_dom = 'Inter' THEN 1 END) as intl_count,
        COUNT(CASE WHEN inter_dom = 'Dom' THEN 1 END) as domestic_count,
        ROUND(AVG(todep), 2) as avg_depression,
        ROUND(AVG(tosc), 2) as avg_social,
        ROUND(AVG(toas), 2) as avg_anxiety,
        ROUND(MIN(todep), 2) as min_dep,
        ROUND(MAX(todep), 2) as max_dep,
        ROUND(STDDEV(tosc), 2) as social_variance,
        ROUND(STDDEV(toas), 2) as anxiety_variance
    FROM students
    WHERE inter_dom = 'Inter'
    GROUP BY duration_segment, stay
),
-- CTE: segment_risks
segment_risks AS (
    SELECT 
        duration_segment,
        student_count,
        intl_count,
        domestic_count,
        ROUND((intl_count * 100.0 / SUM(intl_count) OVER()), 1) as segment_percentage,
        avg_depression,
        avg_social,
        avg_anxiety,
        CASE 
            WHEN avg_depression > 18 THEN 'CRITICAL'
            WHEN avg_depression > 14 THEN 'HIGH'
            WHEN avg_depression > 10 THEN 'MODERATE'
            ELSE 'LOW'
        END as depression_risk,
        CASE 
            WHEN avg_anxiety > 65 THEN 'CRITICAL'
            WHEN avg_anxiety > 50 THEN 'HIGH'
            WHEN avg_anxiety > 35 THEN 'MODERATE'
            ELSE 'LOW'
        END as anxiety_risk,
        CASE 
            WHEN avg_social < 20 THEN 'CRITICAL_ISOLATION'
            WHEN avg_social < 35 THEN 'HIGH_ISOLATION'
            WHEN avg_social < 50 THEN 'MODERATE_ISOLATION'
            ELSE 'GOOD_CONNECTEDNESS'
        END as social_connectedness_level,
        social_variance,
        anxiety_variance
    FROM duration_segments
)

-- To view the combination of the both CTE
-- select *
-- from segment_risks 

-- Anayisis to view the Stay Duration Segmentation Analysis
SELECT 
    duration_segment,
    student_count,
    segment_percentage,
    ROUND(intl_count * 100.0 / student_count, 1) as intl_percentage,
    avg_depression,
    depression_risk,
    avg_anxiety,
    anxiety_risk,
    avg_social,
    social_connectedness_level,
    ROUND(social_variance, 2) as social_variance,
    ROUND(anxiety_variance, 2) as anxiety_variance,
    CASE 
        WHEN depression_risk = 'CRITICAL' OR anxiety_risk = 'CRITICAL' THEN 'URGENT_SUPPORT'
        WHEN depression_risk IN ('HIGH', 'MODERATE') OR anxiety_risk IN ('HIGH', 'MODERATE') THEN 'PRIORITY_SUPPORT'
        ELSE 'STANDARD_SUPPORT'
    END as recommended_support_level
FROM segment_risks
ORDER BY 
    CASE 
        WHEN duration_segment = 'Short-stay (1-2yr)' THEN 1
        WHEN duration_segment = 'Medium-stay (3-4yr)' THEN 2
        WHEN duration_segment = 'Long-stay (5+yr)' THEN 3
    END;






-- ============================
-- Query 7
-- ============================
-- SECTION 4.2: International vs Domestic Comparative Studies

-- CTE: population_stats
WITH population_stats AS (
    SELECT 
        inter_dom as student_population,
        COUNT(*) as n,
        COUNT(DISTINCT region) as distinct_regions,
        ROUND(AVG(stay), 2) as avg_stay_years,
        ROUND(MIN(stay), 0) as min_stay,
        ROUND(MAX(stay), 0) as max_stay,
        
        -- Depression metrics
        ROUND(AVG(todep), 2) as depression_mean,
        ROUND(STDDEV(todep), 2) as depression_sd,
        ROUND(MIN(todep), 2) as depression_min,
        ROUND(MAX(todep), 2) as depression_max,
        
        -- Social Connectedness metrics
        ROUND(AVG(tosc), 2) as social_mean,
        ROUND(STDDEV(tosc), 2) as social_sd,
        ROUND(MIN(tosc), 2) as social_min,
        ROUND(MAX(tosc), 2) as social_max,
        
        -- Anxiety metrics
        ROUND(AVG(toas), 2) as anxiety_mean,
        ROUND(STDDEV(toas), 2) as anxiety_sd,
        ROUND(MIN(toas), 2) as anxiety_min,
        ROUND(MAX(toas), 2) as anxiety_max
    FROM students
    GROUP BY inter_dom
),

-- CTE: risk_prevalence
risk_prevalence AS (
    SELECT 
        inter_dom,
        COUNT(*) as n,
        COUNT(CASE WHEN todep >= 15 THEN 1 END) as high_depression_count,
        ROUND(COUNT(CASE WHEN todep >= 15 THEN 1 END) * 100.0 / COUNT(*), 1) as high_depression_pct,
        COUNT(CASE WHEN toas >= 50 THEN 1 END) as high_anxiety_count,
        ROUND(COUNT(CASE WHEN toas >= 50 THEN 1 END) * 100.0 / COUNT(*), 1) as high_anxiety_pct,
        COUNT(CASE WHEN tosc < 40 THEN 1 END) as low_social_count,
        ROUND(COUNT(CASE WHEN tosc < 40 THEN 1 END) * 100.0 / COUNT(*), 1) as low_social_pct,
        COUNT(CASE WHEN todep >= 15 AND toas >= 50 THEN 1 END) as comorbid_count,
        ROUND(COUNT(CASE WHEN todep >= 15 AND toas >= 50 THEN 1 END) * 100.0 / COUNT(*), 1) as comorbid_pct
    FROM students
    GROUP BY inter_dom
)

-- ANnalysis of International vs Domestic Comparative Studies
SELECT 
    ps.student_population,
    ps.n as total_population,
    ROUND(ps.n * 100.0 / SUM(ps.n) OVER(), 1) as population_pct,
    ps.distinct_regions,
    ps.avg_stay_years,
    CONCAT(ps.min_stay, '-', ps.max_stay, ' yrs') as stay_range,
    
    CONCAT(ps.depression_mean, ' ± ', ps.depression_sd) as depression_summary,
    CONCAT(ps.depression_min, '-', ps.depression_max) as depression_range,
    ps.depression_mean as depression_mean_numeric,
    
    CONCAT(ps.anxiety_mean, ' ± ', ps.anxiety_sd) as anxiety_summary,
    CONCAT(ps.anxiety_min, '-', ps.anxiety_max) as anxiety_range,
    ps.anxiety_mean as anxiety_mean_numeric,
    
    CONCAT(ps.social_mean, ' ± ', ps.social_sd) as social_summary,
    CONCAT(ps.social_min, '-', ps.social_max) as social_range,
    ps.social_mean as social_mean_numeric,
    
    rp.high_depression_pct,
    rp.high_anxiety_pct,
    rp.low_social_pct,
    rp.comorbid_pct,
    
    CASE 
        WHEN ps.depression_mean > 14 AND ps.anxiety_mean > 50 THEN 'HIGH_BURDEN'
        WHEN ps.depression_mean > 12 OR ps.anxiety_mean > 45 THEN 'MODERATE_BURDEN'
        ELSE 'LOW_BURDEN'
    END as overall_burden_level
FROM population_stats as ps
JOIN risk_prevalence rp ON ps.student_population = rp.inter_dom
ORDER BY 
    CASE WHEN ps.student_population = 'Inter' THEN 1 ELSE 2 END;

-- ============================
-- Query 8
-- ============================
-- SECTION 4.3: Mental Health Metric Scoring & Risk Stratification
WITH normalized_scores AS (
    SELECT 
        id,
        inter_dom,
        stay,
        region,
        todep,
        tosc,
        toas,
        -- Normalize depression to 0-100 scale (PHQ-9: 0-50 -> 0-100)
        ROUND((todep / 50.0) * 100, 1) as depression_normalized,
        -- Social connectedness already 0-100
        tosc as social_normalized,
        -- Anxiety already 0-100
        toas as anxiety_normalized,
        -- Depression risk component (higher = worse)
        CASE 
            WHEN todep >= 20 THEN 4
            WHEN todep >= 15 THEN 3
            WHEN todep >= 10 THEN 2
            WHEN todep >= 5 THEN 1
            ELSE 0
        END as depression_risk_score,
        -- Anxiety risk component (higher = worse)
        CASE 
            WHEN toas >= 75 THEN 4
            WHEN toas >= 50 THEN 3
            WHEN toas >= 35 THEN 2
            WHEN toas >= 20 THEN 1
            ELSE 0
        END as anxiety_risk_score,
        -- Social connectedness protective component (higher = better)
        CASE 
            WHEN tosc >= 75 THEN 4
            WHEN tosc >= 50 THEN 3
            WHEN tosc >= 35 THEN 2
            WHEN tosc >= 20 THEN 1
            ELSE 0
        END as social_protection_score
    FROM students
    WHERE inter_dom = 'Inter'
),
composite_scores AS (
    SELECT 
        id,
        inter_dom,
        stay,
        region,
        todep,
        tosc,
        toas,
        depression_normalized,
        social_normalized,
        anxiety_normalized,
        -- Composite risk score (0-8, higher = more at risk)
        (depression_risk_score + anxiety_risk_score - social_protection_score) as composite_risk_score,
        -- Overall wellbeing score (0-100, higher = better)
        ROUND((100 - (depression_normalized * 0.3 + anxiety_normalized * 0.35 + (100 - social_normalized) * 0.35)), 1) as wellbeing_score,
        CASE 
            WHEN (depression_risk_score + anxiety_risk_score) >= 6 OR social_protection_score <= 1 THEN 'CRITICAL'
            WHEN (depression_risk_score + anxiety_risk_score) >= 4 OR social_protection_score = 2 THEN 'HIGH'
            WHEN (depression_risk_score + anxiety_risk_score) >= 2 THEN 'MODERATE'
            ELSE 'LOW'
        END as risk_level
    FROM normalized_scores
)
SELECT 
    inter_dom,
    COUNT(*) as n,
    ROUND(AVG(wellbeing_score), 2) as avg_wellbeing_score,
    ROUND(STDDEV(wellbeing_score), 2) as wellbeing_sd,
    COUNT(CASE WHEN risk_level = 'CRITICAL' THEN 1 END) as critical_count,
    ROUND(COUNT(CASE WHEN risk_level = 'CRITICAL' THEN 1 END) * 100.0 / COUNT(*), 1) as critical_pct,
    COUNT(CASE WHEN risk_level = 'HIGH' THEN 1 END) as high_count,
    ROUND(COUNT(CASE WHEN risk_level = 'HIGH' THEN 1 END) * 100.0 / COUNT(*), 1) as high_pct,
    COUNT(CASE WHEN risk_level = 'MODERATE' THEN 1 END) as moderate_count,
    ROUND(COUNT(CASE WHEN risk_level = 'MODERATE' THEN 1 END) * 100.0 / COUNT(*), 1) as moderate_pct,
    COUNT(CASE WHEN risk_level = 'LOW' THEN 1 END) as low_count,
    ROUND(COUNT(CASE WHEN risk_level = 'LOW' THEN 1 END) * 100.0 / COUNT(*), 1) as low_pct,
    -- Overall risk burden
    ROUND((COUNT(CASE WHEN risk_level IN ('CRITICAL', 'HIGH') THEN 1 END) * 100.0 / COUNT(*)), 1) as at_risk_pct,
    -- Average composite risk
    ROUND(AVG(composite_risk_score), 2) as avg_composite_risk,
    CASE 
        WHEN AVG(composite_risk_score) >= 4 THEN 'HIGH_BURDEN'
        WHEN AVG(composite_risk_score) >= 2 THEN 'MODERATE_BURDEN'
        ELSE 'LOW_BURDEN'
    END as population_burden_level
FROM composite_scores
GROUP BY inter_dom;

-- ============================
-- Query 9
-- ============================
-- SECTION 4.4: Cross-Cultural Wellbeing Patterns
WITH regional_profiles AS (
    SELECT 
        region,
        COUNT(*) as n,
        COUNT(CASE WHEN inter_dom = 'Inter' THEN 1 END) as intl_count,
        ROUND(AVG(stay), 2) as avg_stay,
        
        ROUND(AVG(todep), 2) as depression_mean,
        ROUND(STDDEV(todep), 2) as depression_sd,
        COUNT(CASE WHEN todep >= 15 THEN 1 END) as elevated_depression,
        ROUND(COUNT(CASE WHEN todep >= 15 THEN 1 END) * 100.0 / COUNT(*), 1) as depression_prevalence_pct,
        
        ROUND(AVG(toas), 2) as anxiety_mean,
        ROUND(STDDEV(toas), 2) as anxiety_sd,
        COUNT(CASE WHEN toas >= 50 THEN 1 END) as elevated_anxiety,
        ROUND(COUNT(CASE WHEN toas >= 50 THEN 1 END) * 100.0 / COUNT(*), 1) as anxiety_prevalence_pct,
        
        ROUND(AVG(tosc), 2) as social_mean,
        ROUND(STDDEV(tosc), 2) as social_sd,
        COUNT(CASE WHEN tosc < 40 THEN 1 END) as low_social,
        ROUND(COUNT(CASE WHEN tosc < 40 THEN 1 END) * 100.0 / COUNT(*), 1) as isolation_prevalence_pct
    FROM students
    WHERE inter_dom = 'Inter'
    GROUP BY region
)
SELECT 
    region,
    n as region_student_count,
    ROUND(n * 100.0 / SUM(n) OVER(), 1) as region_pct_of_intl,
    avg_stay as avg_years_enrolled,
    
    -- Depression profile
    depression_mean,
    CONCAT(depression_mean, ' ± ', depression_sd) as depression_profile,
    depression_prevalence_pct as depression_at_risk_pct,
    
    -- Anxiety profile
    anxiety_mean,
    CONCAT(anxiety_mean, ' ± ', anxiety_sd) as anxiety_profile,
    anxiety_prevalence_pct as anxiety_at_risk_pct,
    
    -- Social connectedness profile
    social_mean,
    CONCAT(social_mean, ' ± ', social_sd) as social_profile,
    isolation_prevalence_pct as isolation_pct,
    
    -- Overall risk classification
    CASE 
        WHEN depression_prevalence_pct > 50 AND anxiety_prevalence_pct > 40 THEN 'HIGH_RISK_CULTURE'
        WHEN depression_prevalence_pct > 40 OR anxiety_prevalence_pct > 35 THEN 'MODERATE_RISK_CULTURE'
        ELSE 'STANDARD_RISK_CULTURE'
    END as cultural_risk_profile,
    
    -- Adaptation indicators
    CASE 
        WHEN avg_stay > 4 AND social_mean > 50 THEN 'STRONG_ADAPTATION'
        WHEN avg_stay > 4 AND social_mean <= 50 THEN 'MIXED_ADAPTATION'
        WHEN avg_stay <= 3 THEN 'EARLY_PHASE'
        ELSE 'DEVELOPING_ADAPTATION'
    END as adaptation_trajectory,
    
    -- Support need intensity
    ROUND((depression_prevalence_pct + anxiety_prevalence_pct + isolation_prevalence_pct) / 3, 1) as avg_risk_prevalence
FROM regional_profiles
ORDER BY n DESC;

-- ============================
-- Query 10
-- ============================
-- SECTION 4.5: Duration-Based Risk Prediction Models
WITH risk_factors AS (
    SELECT 
        CASE 
            WHEN stay BETWEEN 1 AND 2 THEN 'Phase1_0-2yr'
            WHEN stay BETWEEN 3 AND 4 THEN 'Phase2_3-4yr'
            WHEN stay >= 5 THEN 'Phase3_5+yr'
        END as enrollment_phase,
        stay,
        region,
        COUNT(*) as n,
        COUNT(CASE WHEN todep >= 15 THEN 1 END) as depression_cases,
        COUNT(CASE WHEN toas >= 50 THEN 1 END) as anxiety_cases,
        COUNT(CASE WHEN tosc < 40 THEN 1 END) as isolation_cases,
        COUNT(CASE WHEN (todep >= 15 AND toas >= 50) THEN 1 END) as comorbid_cases,
        
        ROUND(AVG(CASE WHEN todep >= 15 THEN 1 ELSE 0 END) * 100, 1) as depression_risk_rate,
        ROUND(AVG(CASE WHEN toas >= 50 THEN 1 ELSE 0 END) * 100, 1) as anxiety_risk_rate,
        ROUND(AVG(CASE WHEN tosc < 40 THEN 1 ELSE 0 END) * 100, 1) as isolation_rate,
        
        -- Risk score (weighted combination)
        ROUND(
            (COUNT(CASE WHEN todep >= 15 THEN 1 END) * 0.3 +
             COUNT(CASE WHEN toas >= 50 THEN 1 END) * 0.35 +
             COUNT(CASE WHEN tosc < 40 THEN 1 END) * 0.35) * 100.0 / COUNT(*),
            1
        ) as overall_risk_index
    FROM students
    WHERE inter_dom = 'Inter'
    GROUP BY enrollment_phase, stay, region
),
risk_tiers AS (
    SELECT 
        enrollment_phase,
        stay,
        region,
        n,
        depression_risk_rate,
        anxiety_risk_rate,
        isolation_rate,
        overall_risk_index,
        CASE 
            WHEN overall_risk_index >= 50 THEN 'TIER1_CRITICAL'
            WHEN overall_risk_index >= 35 THEN 'TIER2_HIGH'
            WHEN overall_risk_index >= 20 THEN 'TIER3_MODERATE'
            ELSE 'TIER4_LOW'
        END as risk_tier,
        CASE 
            WHEN stay <= 1 THEN 'EARLY_INTERVENTION_PRIORITY'
            WHEN stay BETWEEN 2 AND 3 THEN 'ADAPTATION_SUPPORT'
            WHEN stay BETWEEN 4 AND 5 THEN 'INTEGRATION_SUPPORT'
            ELSE 'MAINTENANCE_SUPPORT'
        END as support_type,
        -- Predictive probability of any mental health concern
        ROUND((anxiety_risk_rate + depression_risk_rate) / 2, 1) as mental_health_concern_prob,
        -- Social isolation as protective factor concern
        isolation_rate as social_isolation_prob
    FROM risk_factors
)
SELECT 
    enrollment_phase,
    stay as stay_years,
    region,
    n as cohort_size,
    risk_tier,
    support_type,
    ROUND(depression_risk_rate, 1) as depression_risk_pct,
    ROUND(anxiety_risk_rate, 1) as anxiety_risk_pct,
    ROUND(isolation_rate, 1) as isolation_pct,
    ROUND(overall_risk_index, 1) as risk_index_0_100,
    mental_health_concern_prob as concern_probability,
    social_isolation_prob as isolation_probability,
    CASE 
        WHEN n >= 10 THEN 'RELIABLE'
        WHEN n >= 5 THEN 'MODERATE_RELIABILITY'
        ELSE 'SMALL_SAMPLE'
    END as prediction_reliability
FROM risk_tiers
ORDER BY 
    CASE 
        WHEN enrollment_phase = 'Phase1_0-2yr' THEN 1
        WHEN enrollment_phase = 'Phase2_3-4yr' THEN 2
        WHEN enrollment_phase = 'Phase3_5+yr' THEN 3
    END,
    overall_risk_index DESC,
    stay ASC;

-- ============================
-- Query 11
-- ============================
-- Advanced Stay Duration Impact Analysis with Window Functions
WITH duration_base_stats AS (
    SELECT 
        stay,
        inter_dom,
        COUNT(*) as student_count,
        ROUND(AVG(todep), 2) as avg_depression,
        ROUND(AVG(tosc), 2) as avg_social_connectedness,
        ROUND(AVG(toas), 2) as avg_anxiety,
        ROUND(STDDEV(todep), 2) as depression_volatility,
        ROUND(STDDEV(tosc), 2) as social_volatility,
        ROUND(STDDEV(toas), 2) as anxiety_volatility
    FROM students 
    WHERE inter_dom = 'Inter'  -- Focus on international students for this analysis
    GROUP BY stay, inter_dom
),
duration_trends AS (
    SELECT 
        *,
        -- Window functions for trend analysis
        LAG(avg_depression, 1) OVER (ORDER BY stay) as prev_depression,
        LEAD(avg_depression, 1) OVER (ORDER BY stay) as next_depression,
        LAG(avg_social_connectedness, 1) OVER (ORDER BY stay) as prev_social,
        LEAD(avg_social_connectedness, 1) OVER (ORDER BY stay) as next_social,
        LAG(avg_anxiety, 1) OVER (ORDER BY stay) as prev_anxiety,
        LEAD(avg_anxiety, 1) OVER (ORDER BY stay) as next_anxiety,
        
        -- Ranking functions
        RANK() OVER (ORDER BY avg_depression DESC) as depression_risk_rank,
        RANK() OVER (ORDER BY avg_anxiety DESC) as anxiety_risk_rank,
        RANK() OVER (ORDER BY avg_social_connectedness ASC) as social_isolation_rank,
        
        -- Percentile functions
        PERCENT_RANK() OVER (ORDER BY avg_depression) as depression_percentile,
        PERCENT_RANK() OVER (ORDER BY avg_anxiety) as anxiety_percentile,
        PERCENT_RANK() OVER (ORDER BY avg_social_connectedness DESC) as social_percentile,
        
        -- Moving averages for trend smoothing
        ROUND(AVG(avg_depression) OVER (ORDER BY stay ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 2) as depression_3yr_avg,
        ROUND(AVG(avg_social_connectedness) OVER (ORDER BY stay ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 2) as social_3yr_avg,
        ROUND(AVG(avg_anxiety) OVER (ORDER BY stay ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 2) as anxiety_3yr_avg
    FROM duration_base_stats
),
risk_classification AS (
    SELECT 
        *,
        -- Calculate change rates
        CASE 
            WHEN prev_depression IS NOT NULL THEN 
                ROUND(((avg_depression - prev_depression) / prev_depression * 100), 2)
            ELSE NULL 
        END as depression_change_rate,
        
        CASE 
            WHEN prev_social IS NOT NULL THEN 
                ROUND(((avg_social_connectedness - prev_social) / prev_social * 100), 2)
            ELSE NULL 
        END as social_change_rate,
        
        CASE 
            WHEN prev_anxiety IS NOT NULL THEN 
                ROUND(((avg_anxiety - prev_anxiety) / prev_anxiety * 100), 2)
            ELSE NULL 
        END as anxiety_change_rate,
        
        -- Risk level classifications
        CASE 
            WHEN depression_risk_rank <= 3 THEN 'CRITICAL'
            WHEN depression_risk_rank <= 6 THEN 'HIGH'
            ELSE 'MODERATE'
        END as depression_risk_category,
        
        CASE 
            WHEN anxiety_risk_rank <= 3 THEN 'CRITICAL'
            WHEN anxiety_risk_rank <= 6 THEN 'HIGH'
            ELSE 'MODERATE'
        END as anxiety_risk_category,
        
        CASE 
            WHEN social_isolation_rank <= 3 THEN 'SEVERE_ISOLATION'
            WHEN social_isolation_rank <= 6 THEN 'MODERATE_ISOLATION'
            ELSE 'CONNECTED'
        END as social_connection_category
        
    FROM duration_trends
)
SELECT 
    stay as years_of_stay,
    student_count,
    avg_depression,
    depression_3yr_avg as depression_trend,
    depression_change_rate as depression_change_pct,
    depression_risk_category,
    avg_social_connectedness,
    social_3yr_avg as social_trend,
    social_change_rate as social_change_pct,
    social_connection_category,
    avg_anxiety,
    anxiety_3yr_avg as anxiety_trend,
    anxiety_change_rate as anxiety_change_pct,
    anxiety_risk_category,
    depression_volatility,
    social_volatility,
    anxiety_volatility,
    ROUND(depression_percentile * 100, 1) as depression_percentile_rank,
    ROUND(anxiety_percentile * 100, 1) as anxiety_percentile_rank,
    ROUND(social_percentile * 100, 1) as social_connectedness_percentile_rank
FROM risk_classification
ORDER BY stay;

-- ============================
-- Query 12
-- ============================
-- SECTION 5.1: Window Functions for Longitudinal Trend Analysis
WITH longitudinal_data AS (
    SELECT 
        id,
        stay,
        region,
        todep,
        tosc,
        toas,
        -- Row number for identification
        ROW_NUMBER() OVER (ORDER BY stay, todep DESC) as overall_rank,
        ROW_NUMBER() OVER (PARTITION BY region ORDER BY todep DESC) as regional_depression_rank,
        
        -- Ranking (handling ties)
        RANK() OVER (ORDER BY toas DESC) as anxiety_rank,
        DENSE_RANK() OVER (ORDER BY tosc) as social_connectivity_rank,
        
        -- Percentile rankings
        PERCENT_RANK() OVER (ORDER BY todep) as depression_percentile,
        PERCENT_RANK() OVER (ORDER BY toas) as anxiety_percentile,
        PERCENT_RANK() OVER (ORDER BY tosc DESC) as social_percentile,
        
        -- LAG and LEAD for trend analysis
        LAG(todep) OVER (PARTITION BY region ORDER BY stay) as prev_depression,
        LEAD(todep) OVER (PARTITION BY region ORDER BY stay) as next_depression,
        
        -- Trend detection
        CASE 
            WHEN LAG(todep) OVER (PARTITION BY region ORDER BY stay) IS NOT NULL 
                 AND todep > LAG(todep) OVER (PARTITION BY region ORDER BY stay)
            THEN 'WORSENING'
            WHEN LAG(todep) OVER (PARTITION BY region ORDER BY stay) IS NOT NULL 
                 AND todep < LAG(todep) OVER (PARTITION BY region ORDER BY stay)
            THEN 'IMPROVING'
            ELSE 'STABLE'
        END as depression_trend
    FROM students
    WHERE inter_dom = 'Inter'
),
window_analytics AS (
    SELECT 
        stay,
        region,
        COUNT(*) as cohort_size,
        overall_rank,
        
        -- Top risk students
        COUNT(CASE WHEN overall_rank <= 10 THEN 1 END) as top_10_risk_count,
        COUNT(CASE WHEN anxiety_rank <= 20 THEN 1 END) as high_anxiety_count,
        COUNT(CASE WHEN social_connectivity_rank <= 15 THEN 1 END) as low_social_count,
        
        -- Worsening trends
        COUNT(CASE WHEN depression_trend = 'WORSENING' THEN 1 END) as worsening_trend_count,
        COUNT(CASE WHEN depression_trend = 'IMPROVING' THEN 1 END) as improving_trend_count,
        
        ROUND(AVG(CASE WHEN depression_percentile >= 0.75 THEN todep END), 2) as p75_depression,
        ROUND(AVG(CASE WHEN depression_percentile >= 0.50 AND depression_percentile < 0.75 THEN todep END), 2) as p50_75_depression,
        ROUND(AVG(anxiety_percentile * 100), 1) as avg_anxiety_percentile
    FROM longitudinal_data
    GROUP BY stay, region
)
SELECT 
    stay,
    region,
    cohort_size,
    top_10_risk_count,
    ROUND(top_10_risk_count * 100.0 / cohort_size, 1) as top_risk_pct,
    high_anxiety_count,
    low_social_count,
    worsening_trend_count,
    improving_trend_count,
    ROUND(worsening_trend_count * 100.0 / cohort_size, 1) as worsening_trend_pct,
    p75_depression as severe_depression_cohort_avg,
    p50_75_depression as moderate_depression_cohort_avg,
    avg_anxiety_percentile
FROM window_analytics
ORDER BY stay ASC, worsening_trend_pct DESC;

-- ============================
-- Query 13
-- ============================
-- SECTION 5.2: Common Table Expressions (CTEs) for Multi-Metric Analysis
-- Hierarchical CTE structure demonstrating modular query construction

WITH base_metrics AS (
    -- First CTE: Normalize all metrics to 0-100 scale
    SELECT 
        id,
        stay,
        region,
        todep,
        tosc,
        toas,
        ROUND((todep / 50.0) * 100, 1) as depression_normalized,
        tosc as social_normalized,
        toas as anxiety_normalized
    FROM students
    WHERE inter_dom = 'Inter'
),

risk_components AS (
    -- Second CTE: Calculate individual risk dimensions
    SELECT 
        id,
        stay,
        region,
        depression_normalized,
        social_normalized,
        anxiety_normalized,
        CASE 
            WHEN depression_normalized >= 70 THEN 3
            WHEN depression_normalized >= 50 THEN 2
            WHEN depression_normalized >= 30 THEN 1
            ELSE 0
        END as depression_component,
        CASE 
            WHEN anxiety_normalized >= 70 THEN 3
            WHEN anxiety_normalized >= 50 THEN 2
            WHEN anxiety_normalized >= 30 THEN 1
            ELSE 0
        END as anxiety_component,
        CASE 
            WHEN social_normalized < 30 THEN 3
            WHEN social_normalized < 50 THEN 2
            WHEN social_normalized < 70 THEN 1
            ELSE 0
        END as isolation_component
    FROM base_metrics
),

composite_scores AS (
    -- Third CTE: Aggregate components into composite wellbeing score
    SELECT 
        id,
        stay,
        region,
        depression_normalized,
        anxiety_normalized,
        social_normalized,
        depression_component + anxiety_component + isolation_component as composite_risk_score,
        ROUND(
            100 - (depression_normalized * 0.35 + anxiety_normalized * 0.35 + (100 - social_normalized) * 0.30),
            1
        ) as wellbeing_score,
        CASE 
            WHEN (depression_component + anxiety_component + isolation_component) >= 7 THEN 'CRITICAL'
            WHEN (depression_component + anxiety_component + isolation_component) >= 5 THEN 'HIGH'
            WHEN (depression_component + anxiety_component + isolation_component) >= 3 THEN 'MODERATE'
            ELSE 'LOW'
        END as risk_tier
    FROM risk_components
),

cohort_summaries AS (
    -- Fourth CTE: Summarize by stay duration and risk tier
    SELECT 
        stay,
        region,
        risk_tier,
        COUNT(*) as n_students,
        ROUND(AVG(wellbeing_score), 2) as avg_wellbeing,
        ROUND(STDDEV(wellbeing_score), 2) as wellbeing_sd,
        ROUND(AVG(depression_normalized), 2) as avg_depression_norm,
        ROUND(AVG(anxiety_normalized), 2) as avg_anxiety_norm,
        ROUND(AVG(social_normalized), 2) as avg_social_norm,
        ROUND(AVG(composite_risk_score), 2) as avg_risk_score
    FROM composite_scores
    GROUP BY stay, region, risk_tier
),

final_summary AS (
    -- Fifth CTE: Final analytical output with rankings and comparisons
    SELECT 
        stay,
        region,
        risk_tier,
        n_students,
        avg_wellbeing,
        wellbeing_sd,
        avg_depression_norm,
        avg_anxiety_norm,
        avg_social_norm,
        avg_risk_score,
        RANK() OVER (PARTITION BY stay ORDER BY n_students DESC) as regional_rank_by_size,
        RANK() OVER (PARTITION BY risk_tier ORDER BY avg_risk_score DESC) as risk_intensity_rank,
        ROUND(n_students * 100.0 / SUM(n_students) OVER (PARTITION BY stay), 1) as pct_of_cohort
    FROM cohort_summaries
)

SELECT 
    stay as enrollment_year,
    region,
    risk_tier,
    n_students,
    pct_of_cohort,
    regional_rank_by_size,
    risk_intensity_rank,
    avg_wellbeing,
    wellbeing_sd,
    CONCAT(avg_depression_norm, '/', avg_anxiety_norm, '/', avg_social_norm) as normalized_metrics,
    avg_risk_score,
    CASE 
        WHEN avg_risk_score >= 6 THEN 'URGENT_SUPPORT'
        WHEN avg_risk_score >= 4 THEN 'PRIORITY_SUPPORT'
        ELSE 'STANDARD_SUPPORT'
    END as support_recommendation
FROM final_summary
ORDER BY stay ASC, risk_tier DESC;

-- ============================
-- Query 14
-- ============================
-- SECTION 5.3: Advanced Aggregations by Duration Cohorts (ROLLUP)
SELECT 
    COALESCE(
        CASE 
            WHEN stay BETWEEN 1 AND 2 THEN 'Short-stay (1-2yr)'
            WHEN stay BETWEEN 3 AND 4 THEN 'Medium-stay (3-4yr)'
            WHEN stay >= 5 THEN 'Long-stay (5+yr)'
        END,
        'TOTAL'
    ) as duration_cohort,
    COALESCE(region, 'All_Regions') as region,
    COUNT(*) as n_students,
    ROUND(AVG(todep), 2) as avg_depression,
    ROUND(AVG(toas), 2) as avg_anxiety,
    ROUND(AVG(tosc), 2) as avg_social,
    ROUND(
        100 - (AVG(todep)/50 * 100 * 0.35 + AVG(toas) * 0.35 + (100 - AVG(tosc)) * 0.30),
        2
    ) as composite_wellbeing_score,
    COUNT(CASE WHEN todep >= 15 THEN 1 END) as n_elevated_depression,
    COUNT(CASE WHEN toas >= 50 THEN 1 END) as n_elevated_anxiety,
    ROUND(COUNT(CASE WHEN todep >= 15 THEN 1 END) * 100.0 / COUNT(*), 1) as pct_depression_risk,
    ROUND(COUNT(CASE WHEN toas >= 50 THEN 1 END) * 100.0 / COUNT(*), 1) as pct_anxiety_risk
FROM students
WHERE inter_dom = 'Inter'
GROUP BY 
    CASE 
        WHEN stay BETWEEN 1 AND 2 THEN 'Short-stay (1-2yr)'
        WHEN stay BETWEEN 3 AND 4 THEN 'Medium-stay (3-4yr)'
        WHEN stay >= 5 THEN 'Long-stay (5+yr)'
    END,
    region
WITH ROLLUP
ORDER BY 
    CASE 
        WHEN duration_cohort = 'Short-stay (1-2yr)' THEN 1
        WHEN duration_cohort = 'Medium-stay (3-4yr)' THEN 2
        WHEN duration_cohort = 'Long-stay (5+yr)' THEN 3
        WHEN duration_cohort = 'TOTAL' THEN 4
    END,
    n_students DESC;

-- ============================
-- Query 15
-- ============================
-- SECTION 5.4: Statistical SQL Functions for Mental Health Analytics
WITH statistical_profiles AS (
    SELECT 
        region,
        -- Descriptive Statistics
        COUNT(*) as n,
        ROUND(AVG(todep), 2) as depression_mean,
        ROUND(STDDEV(todep), 2) as depression_std,
        ROUND(STDDEV(todep) * STDDEV(todep), 2) as depression_variance,
        
        ROUND(AVG(toas), 2) as anxiety_mean,
        ROUND(STDDEV(toas), 2) as anxiety_std,
        ROUND(STDDEV(toas) * STDDEV(toas), 2) as anxiety_variance,
        
        ROUND(AVG(tosc), 2) as social_mean,
        ROUND(STDDEV(tosc), 2) as social_std,
        ROUND(STDDEV(tosc) * STDDEV(tosc), 2) as social_variance,
        
        -- Quartile Analysis
        ROUND(AVG(CASE 
            WHEN todep >= (SELECT AVG(todep) FROM students WHERE inter_dom='Inter') - 
                           (SELECT STDDEV(todep) FROM students WHERE inter_dom='Inter')
            AND todep <= (SELECT AVG(todep) FROM students WHERE inter_dom='Inter') 
            THEN todep 
        END), 2) as depression_1sd_within,
        
        -- Percentile estimates
        ROUND(MAX(todep), 2) as depression_max,
        ROUND(MIN(todep), 2) as depression_min,
        ROUND(MAX(toas), 2) as anxiety_max,
        ROUND(MIN(toas), 2) as anxiety_min,
        
        -- Range
        ROUND(MAX(todep) - MIN(todep), 2) as depression_range,
        ROUND(MAX(toas) - MIN(toas), 2) as anxiety_range,
        
        -- Coefficient of Variation (normalized variability)
        ROUND((STDDEV(todep) / AVG(todep)) * 100, 2) as depression_cv_pct,
        ROUND((STDDEV(toas) / AVG(toas)) * 100, 2) as anxiety_cv_pct
    FROM students
    WHERE inter_dom = 'Inter'
    GROUP BY region
),

z_score_analysis AS (
    -- Calculate z-scores for outlier detection
    SELECT 
        region,
        COUNT(CASE WHEN ABS((todep - (SELECT AVG(todep) FROM students WHERE inter_dom='Inter')) / 
                             (SELECT STDDEV(todep) FROM students WHERE inter_dom='Inter')) > 2 
              THEN 1 END) as depression_outliers_2sd,
        COUNT(CASE WHEN ABS((toas - (SELECT AVG(toas) FROM students WHERE inter_dom='Inter')) / 
                             (SELECT STDDEV(toas) FROM students WHERE inter_dom='Inter')) > 2 
              THEN 1 END) as anxiety_outliers_2sd,
        COUNT(CASE WHEN ABS((tosc - (SELECT AVG(tosc) FROM students WHERE inter_dom='Inter')) / 
                             (SELECT STDDEV(tosc) FROM students WHERE inter_dom='Inter')) > 2 
              THEN 1 END) as social_outliers_2sd
    FROM students
    WHERE inter_dom = 'Inter'
    GROUP BY region
)

SELECT 
    sp.region,
    sp.n as region_students,
    CONCAT(sp.depression_mean, ' ± ', sp.depression_std) as depression_profile,
    sp.depression_variance,
    sp.depression_cv_pct as depression_variability_pct,
    CONCAT(sp.anxiety_mean, ' ± ', sp.anxiety_std) as anxiety_profile,
    sp.anxiety_variance,
    sp.anxiety_cv_pct as anxiety_variability_pct,
    CONCAT(sp.social_mean, ' ± ', sp.social_std) as social_profile,
    sp.social_variance,
    
    -- Range information
    sp.depression_range as depression_score_range,
    sp.anxiety_range as anxiety_score_range,
    
    -- Outlier detection
    zs.depression_outliers_2sd as depression_outliers,
    zs.anxiety_outliers_2sd as anxiety_outliers,
    zs.social_outliers_2sd as social_outliers,
    
    -- Profile interpretation
    CASE 
        WHEN sp.depression_cv_pct > 50 AND sp.anxiety_cv_pct > 50 THEN 'HIGHLY_HETEROGENEOUS'
        WHEN sp.depression_cv_pct > 35 OR sp.anxiety_cv_pct > 35 THEN 'MODERATELY_HETEROGENEOUS'
        ELSE 'RELATIVELY_HOMOGENEOUS'
    END as population_consistency
FROM statistical_profiles sp
JOIN z_score_analysis zs ON sp.region = zs.region
ORDER BY sp.depression_mean DESC;

-- ============================
-- Query 16
-- ============================
-- SECTION 6.1: Risk Factor Identification & Correlation Analysis (MySQL 8.0 Compatible)
WITH effect_size_analysis AS (
    -- Calculate effect sizes between International and Domestic students
    SELECT 
        'Depression' as risk_factor,
        ROUND(AVG(CASE WHEN inter_dom = 'Inter' THEN todep END), 2) as intl_mean,
        ROUND(AVG(CASE WHEN inter_dom = 'Dom' THEN todep END), 2) as dom_mean,
        ROUND(STDDEV(CASE WHEN inter_dom = 'Inter' THEN todep END), 2) as intl_std,
        ROUND(STDDEV(CASE WHEN inter_dom = 'Dom' THEN todep END), 2) as dom_std,
        
        -- Cohen's d effect size calculation
        ROUND(
            (AVG(CASE WHEN inter_dom = 'Inter' THEN todep END) - 
             AVG(CASE WHEN inter_dom = 'Dom' THEN todep END)) /
            SQRT((
                POWER(STDDEV(CASE WHEN inter_dom = 'Inter' THEN todep END), 2) +
                POWER(STDDEV(CASE WHEN inter_dom = 'Dom' THEN todep END), 2)
            ) / 2),
        3) as cohens_d
        
    FROM students
    
    UNION ALL
    
    SELECT 
        'Anxiety' as risk_factor,
        ROUND(AVG(CASE WHEN inter_dom = 'Inter' THEN toas END), 2),
        ROUND(AVG(CASE WHEN inter_dom = 'Dom' THEN toas END), 2),
        ROUND(STDDEV(CASE WHEN inter_dom = 'Inter' THEN toas END), 2),
        ROUND(STDDEV(CASE WHEN inter_dom = 'Dom' THEN toas END), 2),
        ROUND(
            (AVG(CASE WHEN inter_dom = 'Inter' THEN toas END) - 
             AVG(CASE WHEN inter_dom = 'Dom' THEN toas END)) /
            SQRT((
                POWER(STDDEV(CASE WHEN inter_dom = 'Inter' THEN toas END), 2) +
                POWER(STDDEV(CASE WHEN inter_dom = 'Dom' THEN toas END), 2)
            ) / 2),
        3)
        
    FROM students
    
    UNION ALL
    
    SELECT 
        'Social_Connectedness' as risk_factor,
        ROUND(AVG(CASE WHEN inter_dom = 'Inter' THEN tosc END), 2),
        ROUND(AVG(CASE WHEN inter_dom = 'Dom' THEN tosc END), 2),
        ROUND(STDDEV(CASE WHEN inter_dom = 'Inter' THEN tosc END), 2),
        ROUND(STDDEV(CASE WHEN inter_dom = 'Dom' THEN tosc END), 2),
        ROUND(
            (AVG(CASE WHEN inter_dom = 'Inter' THEN tosc END) - 
             AVG(CASE WHEN inter_dom = 'Dom' THEN tosc END)) /
            SQRT((
                POWER(STDDEV(CASE WHEN inter_dom = 'Inter' THEN tosc END), 2) +
                POWER(STDDEV(CASE WHEN inter_dom = 'Dom' THEN tosc END), 2)
            ) / 2),
        3)
        
    FROM students
),

population_statistics AS (
    SELECT 
        -- Overall population metrics by duration
        stay as study_year,
        COUNT(*) as n,
        ROUND(AVG(todep), 2) as avg_depression,
        ROUND(AVG(toas), 2) as avg_anxiety,
        ROUND(AVG(tosc), 2) as avg_social,
        
        -- At-risk prevalence
        ROUND(COUNT(CASE WHEN todep >= 20 THEN 1 END) * 100.0 / COUNT(*), 1) as high_depression_pct,
        ROUND(COUNT(CASE WHEN toas >= 75 THEN 1 END) * 100.0 / COUNT(*), 1) as high_anxiety_pct,
        ROUND(COUNT(CASE WHEN tosc <= 30 THEN 1 END) * 100.0 / COUNT(*), 1) as high_isolation_pct
    FROM students
    GROUP BY stay
)

SELECT 
    (SELECT esa.risk_factor FROM effect_size_analysis esa LIMIT 1) as analysis_type,
    (SELECT ea.risk_factor FROM effect_size_analysis ea LIMIT 1) as factor_1,
    (SELECT ea.intl_mean FROM effect_size_analysis ea WHERE risk_factor = 'Depression') as depression_intl,
    (SELECT ea.dom_mean FROM effect_size_analysis ea WHERE risk_factor = 'Depression') as depression_dom,
    (SELECT ea.cohens_d FROM effect_size_analysis ea WHERE risk_factor = 'Depression') as depression_cohens_d,
    (SELECT ea.intl_mean FROM effect_size_analysis ea WHERE risk_factor = 'Anxiety') as anxiety_intl,
    (SELECT ea.dom_mean FROM effect_size_analysis ea WHERE risk_factor = 'Anxiety') as anxiety_dom,
    (SELECT ea.cohens_d FROM effect_size_analysis ea WHERE risk_factor = 'Anxiety') as anxiety_cohens_d,
    (SELECT ea.intl_mean FROM effect_size_analysis ea WHERE risk_factor = 'Social_Connectedness') as social_intl,
    (SELECT ea.dom_mean FROM effect_size_analysis ea WHERE risk_factor = 'Social_Connectedness') as social_dom,
    (SELECT ea.cohens_d FROM effect_size_analysis ea WHERE risk_factor = 'Social_Connectedness') as social_cohens_d,
    
    (SELECT MAX(ROUND(avg_depression, 2)) FROM population_statistics) as max_avg_depression,
    (SELECT MAX(high_depression_pct) FROM population_statistics) as max_depression_pct,
    (SELECT MAX(high_anxiety_pct) FROM population_statistics) as max_anxiety_pct,
    (SELECT MAX(high_isolation_pct) FROM population_statistics) as max_isolation_pct;

-- ============================
-- Query 17
-- ============================
-- SECTION 6.2: Early Intervention Timing & Optimal Support Window Analysis (MySQL 8.0)
WITH cohort_analysis AS (
    SELECT 
        stay as study_years,
        COUNT(*) as cohort_size,
        ROUND(AVG(todep), 2) as avg_depression,
        ROUND(AVG(toas), 2) as avg_anxiety,
        ROUND(AVG(tosc), 2) as avg_social_connectedness,
        
        -- Risk level distribution within cohort
        COUNT(CASE WHEN todep >= 20 THEN 1 END) as high_depression_count,
        COUNT(CASE WHEN toas >= 75 THEN 1 END) as high_anxiety_count,
        COUNT(CASE WHEN tosc <= 30 THEN 1 END) as high_isolation_count,
        
        -- Calculate percentages
        ROUND(COUNT(CASE WHEN todep >= 20 THEN 1 END) * 100.0 / COUNT(*), 1) as high_depression_pct,
        ROUND(COUNT(CASE WHEN toas >= 75 THEN 1 END) * 100.0 / COUNT(*), 1) as high_anxiety_pct,
        ROUND(COUNT(CASE WHEN tosc <= 30 THEN 1 END) * 100.0 / COUNT(*), 1) as high_isolation_pct
    FROM students
    GROUP BY stay
),

intervention_opportunity_mapping AS (
    -- Identify optimal intervention windows by duration cohort
    SELECT 
        ca.study_years,
        ca.cohort_size,
        ca.avg_depression,
        ca.avg_anxiety,
        ca.avg_social_connectedness,
        ca.high_depression_pct,
        ca.high_anxiety_pct,
        ca.high_isolation_pct,
        
        -- Intervention urgency scoring (0-100)
        ROUND(
            (ca.high_depression_pct * 0.35) +
            (ca.high_anxiety_pct * 0.35) +
            (ca.high_isolation_pct * 0.30),
        1) as intervention_urgency_score,
        
        -- Stay Years Risk Factor (higher for earlier years)
        CASE 
            WHEN ca.study_years <= 1 THEN 'CRITICAL'
            WHEN ca.study_years <= 2 THEN 'CRITICAL'
            WHEN ca.study_years <= 3 THEN 'HIGH'
            WHEN ca.study_years <= 4 THEN 'MODERATE'
            ELSE 'BASELINE'
        END as intervention_tier,
        
        -- Recommended intervention intensity
        CASE 
            WHEN (ca.high_depression_pct + ca.high_anxiety_pct + ca.high_isolation_pct) / 3 > 60 THEN 'INTENSIVE (Weekly Support)'
            WHEN (ca.high_depression_pct + ca.high_anxiety_pct + ca.high_isolation_pct) / 3 > 40 THEN 'REGULAR (Bi-weekly Support)'
            WHEN (ca.high_depression_pct + ca.high_anxiety_pct + ca.high_isolation_pct) / 3 > 20 THEN 'MODERATE (Monthly Check-in)'
            ELSE 'PREVENTIVE (General Information)'
        END as recommended_intensity
    FROM cohort_analysis ca
)

SELECT 
    iom.study_years,
    iom.cohort_size,
    iom.avg_depression,
    iom.avg_anxiety,
    iom.avg_social_connectedness,
    iom.high_depression_pct,
    iom.high_anxiety_pct,
    iom.high_isolation_pct,
    iom.intervention_urgency_score,
    iom.intervention_tier,
    iom.recommended_intensity
FROM intervention_opportunity_mapping iom
ORDER BY iom.intervention_urgency_score DESC;

-- ============================
-- Query 18
-- ============================
-- SECTION 6.3: Resource Optimization & Cost-Effectiveness Analysis (MySQL 8.0)
WITH population_segments AS (
    SELECT 
        -- Segment analysis
        CASE 
            WHEN stay <= 1 THEN '0-1 Years (Arrival)'
            WHEN stay <= 2 THEN '1-2 Years (Adjustment)'
            WHEN stay <= 4 THEN '3-4 Years (Integration)'
            ELSE '5+ Years (Established)'
        END as student_segment,
        
        inter_dom,
        COUNT(*) as segment_size,
        
        -- Risk metrics
        ROUND(AVG(todep), 2) as segment_avg_depression,
        ROUND(AVG(toas), 2) as segment_avg_anxiety,
        ROUND(AVG(tosc), 2) as segment_avg_social,
        
        -- High-risk population
        COUNT(CASE WHEN todep >= 20 OR toas >= 75 OR tosc <= 30 THEN 1 END) as at_risk_count,
        ROUND(COUNT(CASE WHEN todep >= 20 OR toas >= 75 OR tosc <= 30 THEN 1 END) * 100.0 / COUNT(*), 1) as at_risk_pct,
        
        -- Crisis risk (severe cases)
        COUNT(CASE WHEN todep >= 35 AND toas >= 85 AND tosc <= 20 THEN 1 END) as crisis_risk_count
        
    FROM students
    GROUP BY student_segment, inter_dom
),

resource_requirements AS (
    SELECT 
        student_segment,
        inter_dom,
        segment_size,
        at_risk_count,
        crisis_risk_count,
        at_risk_pct,
        
        -- Resource allocation formulas (based on at-risk population)
        CEIL(at_risk_count / 20.0) as required_counselors,
        CEIL(segment_size / 40.0) as peer_support_coordinators,
        CEIL(crisis_risk_count / 15.0) as crisis_specialists_needed,
        
        -- Cost estimates (annual per role)
        CEIL(at_risk_count / 20.0) * 75000 as counselor_cost,
        CEIL(segment_size / 40.0) * 45000 as peer_support_cost,
        CEIL(crisis_risk_count / 15.0) * 80000 as crisis_support_cost
    FROM population_segments
),

total_resource_summary AS (
    SELECT 
        student_segment,
        SUM(CASE WHEN inter_dom = 'Inter' THEN segment_size ELSE 0 END) as intl_students,
        SUM(CASE WHEN inter_dom = 'Dom' THEN segment_size ELSE 0 END) as dom_students,
        SUM(segment_size) as total_segment_size,
        SUM(CASE WHEN inter_dom = 'Inter' THEN at_risk_count ELSE 0 END) as intl_at_risk,
        SUM(CASE WHEN inter_dom = 'Dom' THEN at_risk_count ELSE 0 END) as dom_at_risk,
        SUM(at_risk_count) as total_at_risk,
        
        SUM(required_counselors) as total_counselors,
        SUM(peer_support_coordinators) as total_peer_coordinators,
        SUM(crisis_specialists_needed) as total_crisis_specialists,
        
        SUM(counselor_cost + peer_support_cost + crisis_support_cost) as segment_total_cost,
        
        -- Cost per student
        ROUND(SUM(counselor_cost + peer_support_cost + crisis_support_cost) / SUM(segment_size), 0) as cost_per_student,
        ROUND(SUM(counselor_cost + peer_support_cost + crisis_support_cost) / SUM(at_risk_count), 0) as cost_per_at_risk_student
        
    FROM resource_requirements
    GROUP BY student_segment
)

SELECT 
    student_segment,
    intl_students,
    dom_students,
    total_segment_size,
    intl_at_risk,
    dom_at_risk,
    total_at_risk,
    total_counselors,
    total_peer_coordinators,
    total_crisis_specialists,
    segment_total_cost,
    cost_per_student,
    cost_per_at_risk_student
FROM total_resource_summary
ORDER BY CASE 
    WHEN student_segment = '0-1 Years (Arrival)' THEN 1
    WHEN student_segment = '1-2 Years (Adjustment)' THEN 2
    WHEN student_segment = '3-4 Years (Integration)' THEN 3
    ELSE 4
END;

-- ============================
-- Query 19
-- ============================
-- SECTION 6.4: Predictive Analytics & Student Retention/Success Modeling (MySQL 8.0)
WITH population_baseline AS (
    SELECT 
        ROUND(AVG(todep), 2) as pop_avg_depression,
        ROUND(AVG(tosc), 2) as pop_avg_social,
        ROUND(AVG(toas), 2) as pop_avg_anxiety,
        ROUND(STDDEV(todep), 2) as pop_std_depression,
        ROUND(STDDEV(tosc), 2) as pop_std_social,
        ROUND(STDDEV(toas), 2) as pop_std_anxiety,
        COUNT(*) as population_size
    FROM students
),

risk_prediction_model AS (
    SELECT 
        s.*,
        pb.pop_avg_depression,
        pb.pop_std_depression,
        pb.pop_avg_social,
        pb.pop_std_social,
        pb.pop_avg_anxiety,
        pb.pop_std_anxiety,
        
        -- Mental health composite score (0-100)
        ROUND(
            ((s.todep / 50.0) * 100 * 0.40) +
            ((s.toas / 100.0) * 100 * 0.35) +
            (s.tosc * 0.25),
        1) as composite_wellbeing_score,
        
        -- Retention risk score (0-100, higher = more at-risk)
        ROUND(
            ((ABS(s.todep - pb.pop_avg_depression) / NULLIF(pb.pop_std_depression, 0)) * 15) +
            ((ABS(s.toas - pb.pop_avg_anxiety) / NULLIF(pb.pop_std_anxiety, 0)) * 15) +
            ((ABS(pb.pop_avg_social - s.tosc) / NULLIF(pb.pop_std_social, 0)) * 15) +
            (CASE WHEN s.stay <= 1 THEN 20 WHEN s.stay <= 2 THEN 15 ELSE 5 END) +
            (CASE WHEN s.inter_dom = 'Inter' THEN 15 ELSE 0 END),
        1) as retention_risk_score,
        
        -- Predicted retention probability (simplified logistic model)
        ROUND(
            100 - ((ABS(s.todep - pb.pop_avg_depression) / NULLIF(pb.pop_std_depression, 0)) * 12) -
            ((ABS(s.toas - pb.pop_avg_anxiety) / NULLIF(pb.pop_std_anxiety, 0)) * 10) -
            ((ABS(pb.pop_avg_social - s.tosc) / NULLIF(pb.pop_std_social, 0)) * 8) -
            (CASE WHEN s.stay <= 1 THEN 15 WHEN s.stay <= 2 THEN 10 ELSE 0 END) -
            (CASE WHEN s.inter_dom = 'Inter' THEN 10 ELSE 0 END),
        1) as predicted_retention_probability
    FROM students s
    CROSS JOIN population_baseline pb
)

SELECT 
    stay,
    inter_dom,
    composite_wellbeing_score,
    retention_risk_score,
    predicted_retention_probability,
    
    -- Categorize retention risk
    CASE 
        WHEN predicted_retention_probability >= 85 THEN 'LOW RISK - Likely to Succeed'
        WHEN predicted_retention_probability >= 70 THEN 'MODERATE RISK - Monitor Carefully'
        WHEN predicted_retention_probability >= 50 THEN 'HIGH RISK - Intervention Needed'
        ELSE 'CRITICAL RISK - Intensive Support Required'
    END as retention_category,
    
    -- Recommended intervention strategy
    CASE 
        WHEN predicted_retention_probability < 50 AND retention_risk_score > 70 THEN 'Crisis Intervention + Mentorship'
        WHEN predicted_retention_probability < 70 THEN 'Enhanced Counseling + Peer Support'
        WHEN predicted_retention_probability >= 85 THEN 'Preventive Check-ins + Career Coaching'
        ELSE 'Regular Support + Community Building'
    END as recommended_intervention,
    
    -- Success likelihood based on multifactorial analysis
    CASE 
        WHEN composite_wellbeing_score >= 70 AND stay >= 2 THEN 'High Success Trajectory'
        WHEN composite_wellbeing_score >= 60 AND stay >= 1 THEN 'On-Track Trajectory'
        WHEN composite_wellbeing_score < 50 THEN 'At-Risk Trajectory'
        ELSE 'Moderate Success Trajectory'
    END as academic_success_trajectory
    
FROM risk_prediction_model
ORDER BY predicted_retention_probability ASC
LIMIT 100;

-- ============================
-- Query 20
-- ============================
-- Advanced Multi-Dimensional Risk Scoring System
WITH row_ranked AS (
    -- Pre-rank rows for percentile calculations (MySQL 8.0 compatible)
    SELECT
        todep, toas, tosc,
        ROW_NUMBER() OVER (ORDER BY todep) as dep_rn,
        ROW_NUMBER() OVER (ORDER BY toas)  as anx_rn,
        ROW_NUMBER() OVER (ORDER BY tosc)  as soc_rn,
        COUNT(*) OVER ()                   as n
    FROM students
),
percentiles AS (
    -- Extract 75th/25th percentile values via ranked rows
    SELECT
        MAX(CASE WHEN dep_rn <= CEIL(n * 0.75) THEN todep END) as dep_p75,
        MAX(CASE WHEN anx_rn <= CEIL(n * 0.75) THEN toas  END) as anx_p75,
        MAX(CASE WHEN soc_rn <= CEIL(n * 0.25) THEN tosc  END) as soc_p25
    FROM row_ranked
),
population_benchmarks AS (
    -- Establish population-wide benchmarks for risk assessment
    SELECT
        ROUND(AVG(s.todep), 2)  as pop_avg_depression,
        ROUND(STDDEV(s.todep), 2) as pop_std_depression,
        ROUND(AVG(s.tosc), 2)   as pop_avg_social,
        ROUND(STDDEV(s.tosc), 2)  as pop_std_social,
        ROUND(AVG(s.toas), 2)   as pop_avg_anxiety,
        ROUND(STDDEV(s.toas), 2)  as pop_std_anxiety,
        ROUND(p.dep_p75, 2)     as depression_75th_percentile,
        ROUND(p.anx_p75, 2)     as anxiety_75th_percentile,
        ROUND(p.soc_p25, 2)     as social_25th_percentile
    FROM students s
    CROSS JOIN percentiles p
),
individual_z_scores AS (
    -- Calculate standardized Z-scores for each student
    SELECT
        s.*,
        pb.pop_avg_depression,
        pb.pop_std_depression,
        pb.pop_avg_social,
        pb.pop_std_social,
        pb.pop_avg_anxiety,
        pb.pop_std_anxiety,
        pb.depression_75th_percentile,
        pb.anxiety_75th_percentile,
        pb.social_25th_percentile,

        -- Z-score calculations (standardized scores)
        ROUND((s.todep - pb.pop_avg_depression) / NULLIF(pb.pop_std_depression, 0), 3) as depression_z_score,
        ROUND((s.tosc  - pb.pop_avg_social)      / NULLIF(pb.pop_std_social, 0),      3) as social_z_score,
        ROUND((s.toas  - pb.pop_avg_anxiety)     / NULLIF(pb.pop_std_anxiety, 0),     3) as anxiety_z_score
    FROM students s
    CROSS JOIN population_benchmarks pb
),
composite_risk_scores AS (
    -- Create composite risk scoring system
    SELECT
        *,
        -- Individual risk flags
        CASE
            WHEN depression_z_score > 2   THEN 4
            WHEN depression_z_score > 1.5 THEN 3
            WHEN depression_z_score > 1   THEN 2
            WHEN depression_z_score > 0.5 THEN 1
            ELSE 0
        END as depression_risk_score,

        CASE
            WHEN anxiety_z_score > 2   THEN 4
            WHEN anxiety_z_score > 1.5 THEN 3
            WHEN anxiety_z_score > 1   THEN 2
            WHEN anxiety_z_score > 0.5 THEN 1
            ELSE 0
        END as anxiety_risk_score,

        CASE
            WHEN social_z_score < -2   THEN 4
            WHEN social_z_score < -1.5 THEN 3
            WHEN social_z_score < -1   THEN 2
            WHEN social_z_score < -0.5 THEN 1
            ELSE 0
        END as social_isolation_score,

        -- Stay duration risk multiplier
        CASE
            WHEN stay <= 2 THEN 1.3
            WHEN stay <= 4 THEN 1.1
            ELSE 1.0
        END as duration_risk_multiplier,

        -- International student risk multiplier
        CASE
            WHEN inter_dom = 'Inter' THEN 1.2
            ELSE 1.0
        END as international_risk_multiplier
    FROM individual_z_scores
),
final_risk_assessment AS (
    SELECT
        *,
        -- Calculate composite risk score
        ROUND((
            (depression_risk_score * 0.4) +
            (anxiety_risk_score    * 0.35) +
            (social_isolation_score * 0.25)
        ) * duration_risk_multiplier * international_risk_multiplier, 2) as composite_risk_score,

        -- Individual percentile ranks
        PERCENT_RANK() OVER (ORDER BY todep DESC) * 100 as depression_percentile,
        PERCENT_RANK() OVER (ORDER BY toas  DESC) * 100 as anxiety_percentile,
        PERCENT_RANK() OVER (ORDER BY tosc       ) * 100 as social_isolation_percentile
    FROM composite_risk_scores
)
SELECT
    stay,
    inter_dom,
    todep  as depression_score,
    tosc   as social_connectedness_score,
    toas   as anxiety_score,
    ROUND(depression_z_score, 2) as depression_z_score,
    ROUND(social_z_score, 2)     as social_z_score,
    ROUND(anxiety_z_score, 2)    as anxiety_z_score,
    depression_risk_score,
    anxiety_risk_score,
    social_isolation_score,
    composite_risk_score,
    ROUND(depression_percentile, 1)        as depression_percentile_rank,
    ROUND(anxiety_percentile, 1)           as anxiety_percentile_rank,
    ROUND(social_isolation_percentile, 1)  as social_isolation_percentile_rank,

    -- Final risk categorization
    CASE
        WHEN composite_risk_score >= 4.0 THEN 'CRITICAL - Immediate Intervention Required'
        WHEN composite_risk_score >= 3.0 THEN 'HIGH - Urgent Support Needed'
        WHEN composite_risk_score >= 2.0 THEN 'MODERATE - Enhanced Monitoring'
        WHEN composite_risk_score >= 1.0 THEN 'MILD - Preventive Support'
        ELSE 'LOW - Regular Monitoring'
    END as risk_category,

    -- Specific intervention recommendations
    CASE
        WHEN depression_risk_score >= 3 AND anxiety_risk_score >= 3 THEN 'Dual Depression/Anxiety Protocol'
        WHEN depression_risk_score >= 3 THEN 'Depression Intervention Protocol'
        WHEN anxiety_risk_score >= 3    THEN 'Anxiety Management Protocol'
        WHEN social_isolation_score >= 3 THEN 'Social Integration Program'
        WHEN composite_risk_score >= 2.0 THEN 'General Wellbeing Support'
        ELSE 'Preventive Care'
    END as recommended_intervention

FROM final_risk_assessment
WHERE composite_risk_score >= 2.0
ORDER BY composite_risk_score DESC, stay ASC
LIMIT 50;

-- ============================
-- Query 21
-- ============================
-- Comprehensive Comparative Analysis Between Student Populations
WITH population_metrics AS (
    SELECT 
        inter_dom,
        stay,
        COUNT(*) as sample_size,
        ROUND(AVG(todep), 3) as mean_depression,
        ROUND(AVG(tosc), 3) as mean_social,
        ROUND(AVG(toas), 3) as mean_anxiety,
        ROUND(VARIANCE(todep), 3) as var_depression,
        ROUND(VARIANCE(tosc), 3) as var_social,
        ROUND(VARIANCE(toas), 3) as var_anxiety,
        ROUND(STDDEV(todep), 3) as std_depression,
        ROUND(STDDEV(tosc), 3) as std_social,
        ROUND(STDDEV(toas), 3) as std_anxiety,
        MIN(todep) as min_depression,
        MAX(todep) as max_depression,
        MIN(tosc) as min_social,
        MAX(tosc) as max_social,
        MIN(toas) as min_anxiety,
        MAX(toas) as max_anxiety
    FROM students
    GROUP BY inter_dom, stay
),
cross_population_comparison AS (
    SELECT 
        i.stay,
        i.sample_size as international_sample,
        d.sample_size as domestic_sample,
        i.mean_depression as intl_depression,
        d.mean_depression as dom_depression,
        ROUND(ABS(i.mean_depression - d.mean_depression), 3) as depression_difference,
        ROUND(((i.mean_depression - d.mean_depression) / d.mean_depression * 100), 2) as depression_pct_difference,
        
        i.mean_social as intl_social,
        d.mean_social as dom_social,
        ROUND(ABS(i.mean_social - d.mean_social), 3) as social_difference,
        ROUND(((i.mean_social - d.mean_social) / d.mean_social * 100), 2) as social_pct_difference,
        
        i.mean_anxiety as intl_anxiety,
        d.mean_anxiety as dom_anxiety,
        ROUND(ABS(i.mean_anxiety - d.mean_anxiety), 3) as anxiety_difference,
        ROUND(((i.mean_anxiety - d.mean_anxiety) / d.mean_anxiety * 100), 2) as anxiety_pct_difference,
        
        -- Effect size calculations (Cohen's d approximation)
        ROUND(ABS(i.mean_depression - d.mean_depression) / 
              SQRT((i.var_depression + d.var_depression) / 2), 3) as depression_effect_size,
        ROUND(ABS(i.mean_social - d.mean_social) / 
              SQRT((i.var_social + d.var_social) / 2), 3) as social_effect_size,
        ROUND(ABS(i.mean_anxiety - d.mean_anxiety) / 
              SQRT((i.var_anxiety + d.var_anxiety) / 2), 3) as anxiety_effect_size,
              
        -- Confidence interval approximations
        ROUND(1.96 * SQRT((i.var_depression/i.sample_size) + (d.var_depression/d.sample_size)), 3) as depression_ci_margin,
        ROUND(1.96 * SQRT((i.var_social/i.sample_size) + (d.var_social/d.sample_size)), 3) as social_ci_margin,
        ROUND(1.96 * SQRT((i.var_anxiety/i.sample_size) + (d.var_anxiety/d.sample_size)), 3) as anxiety_ci_margin
        
    FROM population_metrics i
    INNER JOIN population_metrics d ON i.stay = d.stay
    WHERE i.inter_dom = 'Inter' AND d.inter_dom = 'Dom'
    AND i.sample_size >= 5 AND d.sample_size >= 5  -- Minimum sample size for reliable comparison
),
significance_assessment AS (
    SELECT 
        *,
        -- Statistical significance indicators (simplified)
        CASE 
            WHEN depression_effect_size >= 0.8 THEN 'Large Effect'
            WHEN depression_effect_size >= 0.5 THEN 'Medium Effect'
            WHEN depression_effect_size >= 0.2 THEN 'Small Effect'
            ELSE 'Negligible Effect'
        END as depression_effect_interpretation,
        
        CASE 
            WHEN social_effect_size >= 0.8 THEN 'Large Effect'
            WHEN social_effect_size >= 0.5 THEN 'Medium Effect'
            WHEN social_effect_size >= 0.2 THEN 'Small Effect'
            ELSE 'Negligible Effect'
        END as social_effect_interpretation,
        
        CASE 
            WHEN anxiety_effect_size >= 0.8 THEN 'Large Effect'
            WHEN anxiety_effect_size >= 0.5 THEN 'Medium Effect'
            WHEN anxiety_effect_size >= 0.2 THEN 'Small Effect'
            ELSE 'Negligible Effect'
        END as anxiety_effect_interpretation,
        
        -- Priority flags for intervention
        CASE 
            WHEN depression_effect_size >= 0.5 AND depression_pct_difference >= 20 THEN 'HIGH_PRIORITY'
            WHEN depression_effect_size >= 0.3 AND depression_pct_difference >= 15 THEN 'MEDIUM_PRIORITY'
            WHEN depression_effect_size >= 0.2 AND depression_pct_difference >= 10 THEN 'LOW_PRIORITY'
            ELSE 'MONITOR'
        END as depression_intervention_priority,
        
        CASE 
            WHEN anxiety_effect_size >= 0.5 AND anxiety_pct_difference >= 20 THEN 'HIGH_PRIORITY'
            WHEN anxiety_effect_size >= 0.3 AND anxiety_pct_difference >= 15 THEN 'MEDIUM_PRIORITY'
            WHEN anxiety_effect_size >= 0.2 AND anxiety_pct_difference >= 10 THEN 'LOW_PRIORITY'
            ELSE 'MONITOR'
        END as anxiety_intervention_priority,
        
        CASE 
            WHEN social_effect_size >= 0.5 AND ABS(social_pct_difference) >= 20 THEN 'HIGH_PRIORITY'
            WHEN social_effect_size >= 0.3 AND ABS(social_pct_difference) >= 15 THEN 'MEDIUM_PRIORITY'
            WHEN social_effect_size >= 0.2 AND ABS(social_pct_difference) >= 10 THEN 'LOW_PRIORITY'
            ELSE 'MONITOR'
        END as social_intervention_priority
    FROM cross_population_comparison
)
SELECT 
    stay as years_of_stay,
    international_sample,
    domestic_sample,
    intl_depression,
    dom_depression,
    depression_difference,
    depression_pct_difference,
    depression_effect_size,
    depression_effect_interpretation,
    depression_intervention_priority,
    intl_social,
    dom_social,
    social_difference,
    social_pct_difference,
    social_effect_size,
    social_effect_interpretation,
    social_intervention_priority,
    intl_anxiety,
    dom_anxiety,
    anxiety_difference,
    anxiety_pct_difference,
    anxiety_effect_size,
    anxiety_effect_interpretation,
    anxiety_intervention_priority
FROM significance_assessment
ORDER BY stay;