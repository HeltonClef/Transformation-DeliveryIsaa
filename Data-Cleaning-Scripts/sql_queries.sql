-- SQL Queries for Health Data Reporting
-- Oladokun Clement - ISAA Application Portfolio

-- ============================================
-- 1. FACILITY PERFORMANCE REPORT
-- ============================================
SELECT 
    facility_code,
    facility_name,
    COUNT(*) as total_records,
    SUM(CASE WHEN test_result = 'Positive' THEN 1 ELSE 0 END) as positive_cases,
    SUM(CASE WHEN test_result = 'Negative' THEN 1 ELSE 0 END) as negative_cases,
    ROUND(
        SUM(CASE WHEN test_result = 'Positive' THEN 1 ELSE 0 END)::FLOAT / 
        NULLIF(COUNT(*), 0) * 100, 2
    ) as positivity_rate,
    ROUND(AVG(temperature), 2) as avg_temperature,
    ROUND(AVG(data_quality_score), 2) as avg_quality_score,
    MIN(collection_date) as earliest_date,
    MAX(collection_date) as latest_date
FROM health_surveillance_records
WHERE collection_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY facility_code, facility_name
ORDER BY total_records DESC;

-- ============================================
-- 2. DATA QUALITY METRICS
-- ============================================
SELECT 
    'Data Quality Dashboard' as report_type,
    COUNT(*) as total_records,
    
    -- Completeness metrics
    SUM(CASE WHEN patient_id IS NOT NULL THEN 1 ELSE 0 END) as records_with_patient_id,
    SUM(CASE WHEN test_date IS NOT NULL THEN 1 ELSE 0 END) as records_with_test_date,
    SUM(CASE WHEN test_result IS NOT NULL THEN 1 ELSE 0 END) as records_with_test_result,
    
    -- Calculate completeness percentages
    ROUND(
        SUM(CASE WHEN patient_id IS NOT NULL THEN 1 ELSE 0 END)::FLOAT / 
        NULLIF(COUNT(*), 0) * 100, 2
    ) as patient_id_completeness,
    
    ROUND(
        SUM(CASE WHEN test_date IS NOT NULL THEN 1 ELSE 0 END)::FLOAT / 
        NULLIF(COUNT(*), 0) * 100, 2
    ) as test_date_completeness,
    
    ROUND(
        SUM(CASE WHEN test_result IS NOT NULL THEN 1 ELSE 0 END)::FLOAT / 
        NULLIF(COUNT(*), 0) * 100, 2
    ) as test_result_completeness,
    
    -- Overall completeness
    ROUND(
        (
            (CASE WHEN patient_id IS NOT NULL THEN 1 ELSE 0 END) +
            (CASE WHEN test_date IS NOT NULL THEN 1 ELSE 0 END) +
            (CASE WHEN test_result IS NOT NULL THEN 1 ELSE 0 END)
        )::FLOAT / 3 * 100, 2
    ) as overall_completeness,
    
    -- Timeliness metrics
    ROUND(AVG(EXTRACT(EPOCH FROM (submission_date - collection_date)) / 3600), 1) as avg_processing_hours,
    
    -- Quality metrics
    ROUND(AVG(data_quality_score), 2) as avg_quality_score,
    SUM(CASE WHEN validation_errors > 0 THEN 1 ELSE 0 END) as records_with_errors,
    ROUND(
        SUM(CASE WHEN validation_errors > 0 THEN 1 ELSE 0 END)::FLOAT / 
        NULLIF(COUNT(*), 0) * 100, 2
    ) as error_rate
    
FROM health_surveillance_records
WHERE submission_date >= CURRENT_DATE - INTERVAL '7 days';

-- ============================================
-- 3. DAILY TRENDS
-- ============================================
SELECT 
    DATE(collection_date) as collection_day,
    COUNT(*) as records_collected,
    SUM(CASE WHEN test_result = 'Positive' THEN 1 ELSE 0 END) as positive_cases,
    ROUND(
        SUM(CASE WHEN test_result = 'Positive' THEN 1 ELSE 0 END)::FLOAT / 
        NULLIF(COUNT(*), 0) * 100, 2
    ) as daily_positivity_rate,
    ROUND(AVG(data_quality_score), 2) as avg_daily_quality,
    ROUND(AVG(EXTRACT(EPOCH FROM (submission_date - collection_date)) / 3600), 1) as avg_processing_time
FROM health_surveillance_records
WHERE collection_date >= CURRENT_DATE - INTERVAL '14 days'
GROUP BY DATE(collection_date)
ORDER BY collection_day DESC;

-- ============================================
-- 4. STAFF PERFORMANCE
-- ============================================
SELECT 
    s.staff_id,
    s.staff_name,
    s.facility_code,
    COUNT(r.record_id) as submissions,
    ROUND(AVG(r.data_quality_score), 2) as avg_quality_score,
    ROUND(AVG(EXTRACT(EPOCH FROM (r.submission_date - r.collection_date)) / 3600), 1) as avg_processing_hours,
    SUM(CASE WHEN r.validation_errors > 0 THEN 1 ELSE 0 END) as error_count,
    ROUND(
        SUM(CASE WHEN r.validation_errors > 0 THEN 1 ELSE 0 END)::FLOAT / 
        NULLIF(COUNT(r.record_id), 0) * 100, 2
    ) as error_rate,
    CASE 
        WHEN AVG(r.data_quality_score) >= 90 AND AVG(EXTRACT(EPOCH FROM (r.submission_date - r.collection_date)) / 3600) <= 24 
            THEN 'Excellent'
        WHEN AVG(r.data_quality_score) >= 80 AND AVG(EXTRACT(EPOCH FROM (r.submission_date - r.collection_date)) / 3600) <= 48 
            THEN 'Good'
        WHEN AVG(r.data_quality_score) >= 70 
            THEN 'Satisfactory'
        ELSE 'Needs Improvement'
    END as performance_rating
FROM staff s
LEFT JOIN health_surveillance_records r ON s.staff_id = r.staff_id
WHERE r.submission_date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY s.staff_id, s.staff_name, s.facility_code
HAVING COUNT(r.record_id) >= 5
ORDER BY avg_quality_score DESC, avg_processing_hours ASC;

-- ============================================
-- 5. MONTHLY SUMMARY FOR REPORTING
-- ============================================
SELECT 
    EXTRACT(YEAR FROM collection_date) as year,
    EXTRACT(MONTH FROM collection_date) as month,
    COUNT(*) as total_records,
    SUM(CASE WHEN test_result = 'Positive' THEN 1 ELSE 0 END) as positive_cases,
    ROUND(
        SUM(CASE WHEN test_result = 'Positive' THEN 1 ELSE 0 END)::FLOAT / 
        NULLIF(COUNT(*), 0) * 100, 2
    ) as monthly_positivity_rate,
    ROUND(AVG(data_quality_score), 2) as avg_quality_score,
    MIN(collection_date) as month_start,
    MAX(collection_date) as month_end,
    COUNT(DISTINCT facility_code) as facilities_active,
    COUNT(DISTINCT staff_id) as staff_active
FROM health_surveillance_records
WHERE collection_date >= DATE_TRUNC('year', CURRENT_DATE)
GROUP BY EXTRACT(YEAR FROM collection_date), EXTRACT(MONTH FROM collection_date)
ORDER BY year DESC, month DESC;
