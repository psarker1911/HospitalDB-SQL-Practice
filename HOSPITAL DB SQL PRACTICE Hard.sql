-- 1. Show all of the patients grouped into weight groups.
-- Show the total amount of patients in each weight group.
-- Order the list by the weight group decending.

-- For example, if they weight 100 to 109 they are placed in the 100 weight group,
-- 110-119 = 110 weight group, etc.

SELECT MAX(weight)
FROM patients

SELECT MIN(weight)
FROM patients

SELECT *
FROM patients

/* incorrect below */         
SELECT 
    CASE 
        WHEN weight BETWEEN 100 AND 109 THEN '100'
        WHEN weight BETWEEN 110 AND 119 THEN '110'
        WHEN weight BETWEEN 120 AND 129 THEN '120'
        WHEN weight BETWEEN 130 AND 139 THEN '130'
        WHEN weight BETWEEN 140 AND 149 THEN '140'
        ELSE '<100'
    END AS 'Weight Class',
    first_name, last_name
FROM patients
ORDER BY 'Weight Class' DESC;



/* correct below */

SELECT
  COUNT(*) AS patients_in_group,
  FLOOR(weight / 10) * 10 AS weight_group
FROM patients
GROUP BY weight_group
ORDER BY weight_group DESC;


-- HOSPITAL DB Hard SQL questions continued

-- Show all of the patients grouped into weight groups.
-- Show the total amount of patients in each weight group.
-- Order the list by the weight group decending.

SELECT
  COUNT(*) AS patients_in_group,
  FLOOR(weight / 10) * 10 AS weight_group
FROM patients
GROUP BY weight_group
ORDER BY weight_group DESC;

-- For example, if they weight 100 to 109 they are placed in the 100 weight group, 110-119 = 110 weight group, etc.

-- Show patient_id, weight, height, isObese from the patients table.
-- Display isObese as a boolean 0 or 1.
-- Obese is defined as weight(kg)/(height(m)2) >= 30.
-- weight is in units kg.
-- height is in units cm.

SELECT patient_id, weight, height,
    CASE 
        WHEN (weight/POWER(height/100.0,2)) >= 30 THEN 1
        ELSE 0
    END AS isObese
FROM patients;

-- Show patient_id, first_name, last_name, and attending doctor's specialty.
-- Show only the patients who has a diagnosis as 'Epilepsy' and the doctor's first name is 'Lisa'

-- Check patients, admissions, and doctors tables for required information.


SELECT p.patient_id, p.first_name, p.last_name, d.specialty
FROM admissions AS a
JOIN patients AS p ON a.patient_id = p.patient_id
JOIN doctors AS d ON a.attending_doctor_id = d.doctor_id
WHERE a.diagnosis = 'Epilepsy' AND d.first_name = 'Lisa';


-- All patients who have gone through admissions, can see their medical documents on our site. 
-- Those patients are given a temporary password after their first admission. 
-- Show the patient_id and temp_password.

-- The password must be the following, in order:
-- 1. patient_id
-- 2. the numerical length of patient's last_name
-- 3. year of patient's birth_date

SELECT DISTINCT p.patient_id, 
CONCAT(p.patient_id, LENGTH(p.last_name), YEAR(p.birth_date)) AS temp_password
FROM patients AS p 
JOIN admissions AS a 
ON p.patient_id = a.patient_id;

-- Each admission costs $50 for patients without insurance, and $10 for patients with insurance.
-- All patients with an even patient_id have insurance.
-- Give each patient a 'Yes' if they have insurance, and a 'No' if they don't have insurance. 
-- Add up the admission_total cost for each has_insurance group.

SELECT CASE WHEN patient_id % 2 = 0 Then 'Yes'
ELSE 'No' 
END as has_insurance,
SUM(CASE WHEN patient_id % 2 = 0 Then 10 ELSE 50 END) as cost_after_insurance
FROM admissions 
GROUP BY has_insurance;

 --Show the provinces that has more patients identified as 'M' than 'F'.
 -- Must only show full province_name

SELECT pr.province_name
FROM patients AS p
JOIN province_names AS pr ON p.province_id = pr.province_id
GROUP BY pr.province_name
HAVING SUM(CASE WHEN p.gender = 'M' THEN 1 ELSE 0 END) >
       SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END);

-- We are looking for a specific patient. Pull all columns for the patient who matches the following criteria:
-- - First_name contains an 'r' after the first two letters.
-- - Identifies their gender as 'F'
-- - Born in February, May, or December
-- - Their weight would be between 60kg and 80kg
-- - Their patient_id is an odd number
-- - They are from the city 'Kingston'

SELECT * 
FROM patients
WHERE 
    -- First name contains an 'r' after the first two letters
    SUBSTRING(first_name, 3, LEN(first_name) - 2) LIKE '%r%'
    -- Identifies their gender as 'F'
    AND gender = 'F'
    -- Born in February, May, or December
    AND MONTH(birth_date) IN (2, 5, 12)
    -- Their weight is between 60kg and 80kg
    AND weight BETWEEN 60 AND 80
    -- Their patient_id is an odd number
    AND patient_id % 2 = 1
    -- They are from the city 'Kingston'
    AND city = 'Kingston';

-- Show the percent of patients that have 'M' as their gender. 
-- Round the answer to the nearest hundreth number and in percent form.

SELECT 
    ROUND(
        (CAST(
            (SELECT COUNT(*) FROM patients WHERE gender = 'M') AS FLOAT)
         / 
         CAST((SELECT COUNT(*) FROM patients) AS FLOAT)
        ) * 100, 2) AS Percentage_M
FROM 
    patients
LIMIT 1;

-- OR

SELECT
  round(100 * avg(gender = 'M'), 2) || '%' AS percent_of_male_patients
FROM
  patients;

-- For each day display the total amount of admissions on that day. 

-- Display the amount changed from the previous date.

WITH admission_counts_table AS (
  SELECT admission_date, COUNT(patient_id) AS admission_count
  FROM admissions
  GROUP BY admission_date
  ORDER BY admission_date DESC
)
SELECT
  admission_date, 
  admission_count, 
  admission_count - LAG(admission_count) OVER(ORDER BY admission_date) AS admission_count_change 
FROM admission_counts_table

-- Sort the province names in ascending order in such a way that the province
-- 'Ontario' is always on top.

SELECT province_name 
FROM province_names
ORDER BY 
    CASE WHEN province_name = 'Ontario' THEN 0 ELSE 1 END, 
    province_name ASC;

-- We need a breakdown for the total amount of admissions each doctor
-- has started each year.
-- Show the doctor_id, doctor_full_name, specialty, year, 
-- total_admissions —for that year.

SELECT 
    d.doctor_id, 
    d.first_name || ' ' || d.last_name AS doctor_full_name, 
    d.specialty, 
    CAST(strftime('%Y', a.admission_date) AS INTEGER) AS year, 
    COUNT(a.patient_id) AS total_admissions 
FROM 
    admissions a 
JOIN 
    doctors d ON a.attending_doctor_id = d.doctor_id 
GROUP BY 
    d.doctor_id, doctor_full_name, d.specialty, year 
ORDER BY 
    d.doctor_id, year;
