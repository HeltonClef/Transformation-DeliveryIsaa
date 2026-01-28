-- SQL Report Generator for Health Surveillance Data
-- Author: Oladokun Clement
-- For ISAA Application Portfolio

-- ============================================
-- 1. MONTHLY PERFORMANCE DASHBOARD QUERY
-- ============================================

CREATE OR REPLACE VIEW monthly_performance_dashboard AS
WITH monthly_metrics AS (
    SELECT 
        DATE_TRUNC('month', submission_date) AS report_month,
        facility_id,
        facility_name,
        COUNT(*) AS total_submissions,
        SUM(CASE WHEN data_completeness_score >= 90 THEN 1 ELSE 0 END) AS compliant_submissions,
        AVG(data_completeness_score) AS avg_completeness,
        AVG(TIMESTAMPDIFF(HOUR, collection_date, submission_date)) AS avg_processing_hours,
        COUNT(DISTINCT staff_id) AS active_staff_count,
        MAX(submission_date) AS latest_submission
    FROM health_surveillance_records
    WHERE submission_date >= CURRENT_DATE - INTERVAL '12 months'
        AND data_status = 'approved'
    GROUP BY 1, 2, 3
),
facility_rankings AS (
    SELECT 
        report_month,
        facility_id,
        facility_name,
        total_submissions,
        compliant_submissions,
        ROUND((compliant_submissions::FLOAT / total_submissions) * 100, 2) AS compliance_rate,
        ROUND(avg_completeness, 2) AS avg_completeness_score,
        ROUND(avg_processing_hours, 1) AS avg_processing_time_hours,
        active_staff_count,
        latest_submission,
        RANK() OVER (PARTITION BY report_month ORDER BY compliance_rate DESC) AS compliance_rank,
        CASE 
            WHEN compliance_rate >= 95 THEN 'Excellent'
            WHEN compliance_rate >= 85 THEN 'Good'
            WHEN compliance_rate >= 75 THEN 'Fair'
            ELSE 'Needs Improvement'
        END AS performance_category
    FROM monthly_metrics
)
SELECT * FROM facility_rankings
ORDER BY report_month DESC, compliance_rank ASC;

-- ============================================
-- 2. DATA QUALITY TRENDS QUERY
-- ============================================

SELECT 
    DATE_TRUNC('week', submission_date) AS week_start,
    
    -- Data Completeness Metrics
    COUNT(*) AS total_records,
    SUM(CASE WHEN patient_id IS NOT NULL THEN 1 ELSE 0 END) AS records_with_patient_id,
    SUM(CASE WHEN test_date IS NOT NULL THEN 1 ELSE 0 END) AS records_with_test_date,
    SUM(CASE WHEN test_result IS NOT NULL THEN 1 ELSE 0 END) AS records_with_test_result,
    
    -- Calculate completeness percentages
    ROUND(
        (SUM(CASE WHEN patient_id IS NOT NULL THEN 1 ELSE 0 END)::FLOAT / COUNT(*) * 100),
        2
    ) AS patient_id_completeness,
    
    ROUND(
        (SUM(CASE WHEN test_date IS NOT NULL THEN 1 ELSE 0 END)::FLOAT / COUNT(*) * 100),
        2
    ) AS test_date_completeness,
    
    ROUND(
        (SUM(CASE WHEN test_result IS NOT NULL THEN 1 ELSE 0 END)::FLOAT / COUNT(*) * 100),
        2
    ) AS test_result_completeness,
    
    -- Overall completeness score
    ROUND(
        (
            (CASE WHEN patient_id IS NOT NULL THEN 1 ELSE 0 END) +
            (CASE WHEN test_date IS NOT NULL THEN 1 ELSE 0 END) +
            (CASE WHEN test_result IS NOT NULL THEN 1 ELSE 0 END)
        )::FLOAT / 3 * 100,
        2
    ) AS avg_record_completeness,
    
    -- Error metrics
    SUM(CASE WHEN validation_errors > 0 THEN 1 ELSE 0 END) AS records_with_errors,
    ROUND(AVG(validation_errors), 2) AS avg_errors_per_record,
    
    -- Timeliness metrics
    ROUND(AVG(EXTRACT(EPOCH FROM (submission_date - collection_date)) / 3600), 1) AS avg_processing_hours
    
FROM health_surveillance_records
WHERE submission_date >= CURRENT_DATE - INTERVAL '3 months'
GROUP BY DATE_TRUNC('week', submission_date)
ORDER BY week_start DESC;

-- ============================================
-- 3. STAFF PERFORMANCE REPORT
-- ============================================

CREATE OR REPLACE FUNCTION generate_staff_performance_report(
    start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    end_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE (
    staff_id VARCHAR(50),
    staff_name VARCHAR(100),
    facility_name VARCHAR(100),
    total_submissions INTEGER,
    avg_completeness_score DECIMAL(5,2),
    avg_processing_hours DECIMAL(5,1),
    error_rate DECIMAL(5,2),
    compliance_rate DECIMAL(5,2),
    performance_rating VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    WITH staff_stats AS (
        SELECT 
            sr.staff_id,
            s.staff_name,
            f.facility_name,
            COUNT(*) AS total_submissions,
            ROUND(AVG(sr.data_completeness_score), 2) AS avg_completeness_score,
            ROUND(AVG(EXTRACT(EPOCH FROM (sr.submission_date - sr.collection_date)) / 3600), 1) AS avg_processing_hours,
            ROUND(
                (SUM(CASE WHEN sr.validation_errors > 0 THEN 1 ELSE 0 END)::FLOAT / COUNT(*) * 100),
                2
            ) AS error_rate,
            ROUND(
                (SUM(CASE WHEN sr.data_completeness_score >= 90 THEN 1 ELSE 0 END)::FLOAT / COUNT(*) * 100),
                2
            ) AS compliance_rate
        FROM health_surveillance_records sr
        JOIN staff s ON sr.staff_id = s.staff_id
        JOIN facilities f ON sr.facility_id = f.facility_id
        WHERE sr.submission_date BETWEEN start_date AND end_date
            AND sr.data_status = 'approved'
        GROUP BY sr.staff_id, s.staff_name, f.facility_name
        HAVING COUNT(*) >= 5  -- Only include staff with minimum submissions
    )
    SELECT 
        staff_id,
        staff_name,
        facility_name,
        total_submissions,
        avg_completeness_score,
        avg_processing_hours,
        error_rate,
        compliance_rate,
        CASE 
            WHEN compliance_rate >= 95 AND error_rate <= 5 THEN 'Excellent'
            WHEN compliance_rate >= 85 AND error_rate <= 10 THEN 'Good'
            WHEN compliance_rate >= 75 AND error_rate <= 15 THEN 'Satisfactory'
            ELSE 'Needs Improvement'
        END AS performance_rating
    FROM staff_stats
    ORDER BY compliance_rate DESC, error_rate ASC;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- 4. AUDIT TRAIL REPORT
-- ============================================

SELECT 
    audit_id,
    table_name,
    operation_type,
    record_id,
    old_values,
    new_values,
    changed_by,
    changed_at,
    
    -- Calculate change impact
    CASE 
        WHEN operation_type = 'DELETE' THEN 'High Risk'
        WHEN operation_type = 'UPDATE' AND old_values::jsonb ? 'test_result' THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_level,
    
    -- Extract key changes for readability
    jsonb_pretty(old_values::jsonb - new_values::jsonb) AS key_changes
    
FROM system_audit_trail
WHERE changed_at >= CURRENT_DATE - INTERVAL '7 days'
    AND table_name IN ('health_surveillance_records', 'patient_data', 'test_results')
ORDER BY changed_at DESC, risk_level DESC;

-- ============================================
-- 5. REAL-TIME ALERT QUERY
-- ============================================

-- Monitor for data quality issues in real-time
SELECT 
    'DATA QUALITY ALERT' AS alert_type,
    facility_id,
    facility_name,
    COUNT(*) AS problematic_records,
    STRING_AGG(DISTINCT issue_type, ', ') AS issues_detected,
    MIN(submission_date) AS first_detected,
    MAX(submission_date) AS last_detected
FROM (
    SELECT 
        hsr.facility_id,
        f.facility_name,
        hsr.submission_date,
        CASE 
            WHEN hsr.data_completeness_score < 70 THEN 'Low Completeness'
            WHEN hsr.validation_errors > 3 THEN 'High Error Count'
            WHEN hsr.test_date > CURRENT_DATE THEN 'Future Date'
            WHEN hsr.patient_age > 110 OR hsr.patient_age < 0 THEN 'Invalid Age'
            WHEN hsr.submission_date - hsr.collection_date > INTERVAL '7 days' THEN 'Delayed Submission'
            ELSE 'Other'
        END AS issue_type
    FROM health_surveillance_records hsr
    JOIN facilities f ON hsr.facility_id = f.facility_id
    WHERE hsr.submission_date >= CURRENT_DATE - INTERVAL '24 hours'
        AND (
            hsr.data_completeness_score < 70
            OR hsr.validation_errors > 3
            OR hsr.test_date > CURRENT_DATE
            OR hsr.patient_age > 110 OR hsr.patient_age < 0
            OR (hsr.submission_date - hsr.collection_date) > INTERVAL '7 days'
        )
) AS alerts
GROUP BY facility_id, facility_name
HAVING COUNT(*) > 5  -- Only alert if more than 5 issues
ORDER BY problematic_records DESC;

-- ============================================
-- USAGE INSTRUCTIONS:
-- ============================================
-- 1. Run these queries in your PostgreSQL database
-- 2. Modify table/column names to match your schema
-- 3. Schedule with cron or Windows Task Scheduler
-- 4. Output can be directed to CSV for reporting:
--    \copy (SELECT * FROM monthly_performance_dashboard) TO 'report.csv' CSV HEADER