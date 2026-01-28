-- SQL Queries for Health Data Reporting
-- Oladokun Clement - ISAA Application

-- 1. Basic Report Query
SELECT 
    facility_code,
    COUNT(*) as total_patients,
    AVG(temperature) as avg_temperature,
    SUM(CASE WHEN test_result = 'Positive' THEN 1 ELSE 0 END) as positive_cases,
    SUM(CASE WHEN test_result = 'Negative' THEN 1 ELSE 0 END) as negative_cases
FROM health_records
GROUP BY facility_code
ORDER BY total_patients DESC;

-- 2. Data Quality Check
SELECT 
    'Data Quality Report' as report_type,
    COUNT(*) as total_records,
    SUM(CASE WHEN patient_id IS NULL THEN 1 ELSE 0 END) as missing_patient_id,
    SUM(CASE WHEN test_date IS NULL THEN 1 ELSE 0 END) as missing_test_date,
    SUM(CASE WHEN test_result IS NULL THEN 1 ELSE 0 END) as missing_test_result,
    ROUND(
        (COUNT(*) - SUM(
            CASE WHEN patient_id IS NULL OR test_date IS NULL OR test_result IS NULL 
            THEN 1 ELSE 0 END
        ))::FLOAT / COUNT(*) * 100, 2
    ) as completeness_percentage
FROM health_records;

-- 3. Monthly Trends
SELECT 
    DATE_TRUNC('month', test_date) as month,
    COUNT(*) as tests_conducted,
    SUM(CASE WHEN test_result = 'Positive' THEN 1 ELSE 0 END) as positive_cases,
    ROUND(
        SUM(CASE WHEN test_result = 'Positive' THEN 1 ELSE 0 END)::FLOAT / COUNT(*) * 100, 2
    ) as positivity_rate
FROM health_records
WHERE test_date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY DATE_TRUNC('month', test_date)
ORDER BY month DESC;