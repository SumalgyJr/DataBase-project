-- ============================================================
-- CMPE343 - Airport Management System
-- 15 SQL Queries - MySQL Version
-- ============================================================


-- Query 1: List all airplanes with their model details and current hangar
-- Uses: JOIN
-- Purpose: Full overview of every airplane and where it is parked.

SELECT 
    a.plane_no,
    pm.manufacturer,
    pm.type,
    a.status,
    a.total_flight_hours,
    h.location AS hangar_location
FROM airplane a
JOIN plane_model pm ON a.model_no = pm.model_no
JOIN hangar h ON a.current_hangar_no = h.hangar_no;


-- ============================================================

-- Query 2: Show all testing events with airplane, technician name, and test name
-- Uses: JOIN (multiple)
-- Purpose: Full log of every test performed, who did it, and on which plane.

SELECT 
    te.event_id,
    te.plane_no,
    ae.full_name AS technician_name,
    t.test_name,
    te.test_date,
    te.hours_spent,
    te.score,
    te.remarks
FROM testing_event te
JOIN technician tech ON te.technician_ssn = tech.ssn
JOIN airport_employee ae ON tech.ssn = ae.ssn
JOIN test t ON te.test_id = t.test_id
ORDER BY te.test_date DESC;


-- ============================================================

-- Query 3: Total hours each technician has spent on tests
-- Uses: JOIN, GROUP BY
-- Purpose: Identify which technicians are doing the most work.

SELECT 
    ae.full_name AS technician_name,
    tech.specialization,
    COUNT(te.event_id) AS total_tests,
    SUM(te.hours_spent) AS total_hours_spent,
    ROUND(AVG(te.hours_spent), 2) AS avg_hours_per_test
FROM testing_event te
JOIN technician tech ON te.technician_ssn = tech.ssn
JOIN airport_employee ae ON tech.ssn = ae.ssn
GROUP BY ae.full_name, tech.specialization
ORDER BY total_hours_spent DESC;


-- ============================================================

-- Query 4: Average test score per airplane
-- Uses: JOIN, GROUP BY
-- Purpose: Identify which airplanes are performing well or need attention.

SELECT 
    a.plane_no,
    pm.manufacturer,
    pm.type,
    COUNT(te.event_id) AS number_of_tests,
    ROUND(AVG(te.score), 2) AS average_score,
    MIN(te.score) AS lowest_score,
    MAX(te.score) AS highest_score
FROM airplane a
JOIN plane_model pm ON a.model_no = pm.model_no
LEFT JOIN testing_event te ON a.plane_no = te.plane_no
GROUP BY a.plane_no, pm.manufacturer, pm.type
ORDER BY average_score ASC;


-- ============================================================

-- Query 5: Airplanes that have failed at least one test (score below passing score)
-- Uses: JOIN, Subquery
-- Purpose: Alert management to airplanes that received a failing score.

SELECT 
    a.plane_no,
    pm.manufacturer,
    t.test_name,
    te.score,
    t.passing_score,
    te.test_date,
    ae.full_name AS tested_by
FROM testing_event te
JOIN airplane a ON te.plane_no = a.plane_no
JOIN plane_model pm ON a.model_no = pm.model_no
JOIN test t ON te.test_id = t.test_id
JOIN technician tech ON te.technician_ssn = tech.ssn
JOIN airport_employee ae ON tech.ssn = ae.ssn
WHERE te.score < (
    SELECT t2.passing_score 
    FROM test t2 
    WHERE t2.test_id = te.test_id
)
ORDER BY te.score ASC;


-- ============================================================

-- Query 6: Number of airplanes currently stored in each hangar
-- Uses: JOIN, GROUP BY
-- Purpose: Monitor hangar occupancy and available space.

SELECT 
    h.hangar_no,
    h.location,
    h.capacity AS max_capacity,
    COUNT(a.plane_no) AS planes_currently_stored,
    (h.capacity - COUNT(a.plane_no)) AS available_spots
FROM hangar h
LEFT JOIN airplane a ON h.hangar_no = a.current_hangar_no
GROUP BY h.hangar_no, h.location, h.capacity
ORDER BY planes_currently_stored DESC;


-- ============================================================

-- Query 7: Traffic controllers whose medical exam is older than 1 year
-- Uses: JOIN
-- Purpose: Flag traffic controllers overdue for their annual medical exam.

SELECT 
    ae.full_name,
    tc.tower_assignment,
    tc.shift_schedule,
    tc.last_medical_exam_date,
    DATEDIFF(CURDATE(), tc.last_medical_exam_date) AS days_since_exam
FROM traffic_controller tc
JOIN airport_employee ae ON tc.ssn = ae.ssn
WHERE tc.last_medical_exam_date < DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
ORDER BY tc.last_medical_exam_date ASC;


-- ============================================================

-- Query 8: List all technicians and the plane models they are certified for
-- Uses: JOIN, GROUP BY
-- Purpose: Show management which technicians can work on which models.

SELECT 
    ae.full_name AS technician_name,
    tech.specialization,
    tech.certification_level,
    GROUP_CONCAT(te.model_no SEPARATOR ', ') AS certified_models,
    COUNT(te.model_no) AS number_of_certifications
FROM technician tech
JOIN airport_employee ae ON tech.ssn = ae.ssn
LEFT JOIN technician_expertise te ON tech.ssn = te.technician_ssn
GROUP BY ae.full_name, tech.specialization, tech.certification_level
ORDER BY number_of_certifications DESC;


-- ============================================================

-- Query 9: Technicians certified for more than one plane model
-- Uses: JOIN, GROUP BY, Subquery
-- Purpose: Identify the most versatile technicians.

SELECT 
    ae.full_name AS technician_name,
    tech.specialization,
    COUNT(te.model_no) AS number_of_models
FROM technician tech
JOIN airport_employee ae ON tech.ssn = ae.ssn
JOIN technician_expertise te ON tech.ssn = te.technician_ssn
GROUP BY ae.full_name, tech.specialization
HAVING COUNT(te.model_no) > 1
ORDER BY number_of_models DESC;


-- ============================================================

-- Query 10: Full hangar history for each airplane with formatted dates
-- Uses: JOIN, DATE_FORMAT (TO_CHAR equivalent in MySQL)
-- Purpose: Show the complete storage history of every airplane.

SELECT 
    ha.plane_no,
    h.location AS hangar_location,
    DATE_FORMAT(ha.in_date, '%d/%m/%Y') AS checked_in,
    CASE 
        WHEN ha.out_date IS NULL THEN 'Still in hangar'
        ELSE DATE_FORMAT(ha.out_date, '%d/%m/%Y')
    END AS checked_out,
    ha.reason
FROM hangar_assignment ha
JOIN hangar h ON ha.hangar_no = h.hangar_no
ORDER BY ha.plane_no, ha.in_date ASC;


-- ============================================================

-- Query 11: Most frequently used tests
-- Uses: JOIN, GROUP BY
-- Purpose: Identify which tests are performed most often across the fleet.

SELECT 
    t.test_name,
    t.passing_score,
    t.duration_hours,
    COUNT(te.event_id) AS times_performed,
    ROUND(AVG(te.score), 2) AS average_score_achieved
FROM test t
LEFT JOIN testing_event te ON t.test_id = te.test_id
GROUP BY t.test_name, t.passing_score, t.duration_hours
ORDER BY times_performed DESC;


-- ============================================================

-- Query 12: Employees who are NOT in any union
-- Uses: Subquery
-- Purpose: Data integrity check — every employee should belong to a union.

SELECT 
    ae.ssn,
    ae.full_name,
    ae.hire_date,
    ae.email
FROM airport_employee ae
WHERE ae.ssn NOT IN (
    SELECT eu.ssn 
    FROM employee_union eu
)
ORDER BY ae.hire_date;


-- ============================================================

-- Query 13: Monthly testing activity report
-- Uses: GROUP BY, DATE_FORMAT (TO_CHAR equivalent in MySQL)
-- Purpose: Show management how many tests were conducted each month.

SELECT 
    DATE_FORMAT(te.test_date, '%Y') AS year,
    DATE_FORMAT(te.test_date, '%M') AS month,
    COUNT(te.event_id) AS total_tests_conducted,
    ROUND(AVG(te.score), 2) AS average_score,
    SUM(te.hours_spent) AS total_hours_spent
FROM testing_event te
GROUP BY DATE_FORMAT(te.test_date, '%Y'), DATE_FORMAT(te.test_date, '%M'), DATE_FORMAT(te.test_date, '%Y%m')
ORDER BY DATE_FORMAT(te.test_date, '%Y%m') DESC;


-- ============================================================

-- Query 14: Airplanes that have NEVER been tested
-- Uses: Subquery
-- Purpose: Alert management to airplanes with no test records at all.

SELECT 
    a.plane_no,
    pm.manufacturer,
    pm.type,
    a.status,
    a.acquisition_date,
    a.total_flight_hours
FROM airplane a
JOIN plane_model pm ON a.model_no = pm.model_no
WHERE a.plane_no NOT IN (
    SELECT DISTINCT te.plane_no 
    FROM testing_event te
)
ORDER BY a.acquisition_date;


-- ============================================================

-- Query 15: Technician cost report — total pay per technician based on hours spent
-- Uses: JOIN, GROUP BY
-- Purpose: Calculate how much each technician should be paid based on testing hours.

SELECT 
    ae.full_name AS technician_name,
    tech.certification_level,
    tech.hourly_rate,
    SUM(te.hours_spent) AS total_hours_worked,
    ROUND(SUM(te.hours_spent) * tech.hourly_rate, 2) AS total_pay_due
FROM testing_event te
JOIN technician tech ON te.technician_ssn = tech.ssn
JOIN airport_employee ae ON tech.ssn = ae.ssn
GROUP BY ae.full_name, tech.certification_level, tech.hourly_rate
ORDER BY total_pay_due DESC;