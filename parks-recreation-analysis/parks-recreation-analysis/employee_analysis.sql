/*
===========================================================
PARKS AND RECREATION EMPLOYEE ANALYSIS
===========================================================
Purpose:
This SQL analysis explores employee demographics,
occupations, departments, salaries, age groups and
salary differences across departments.

Tools:
MySQL

Author:
Grace Akanle
===========================================================
*/


/* ---------------------------------------------------------
   1. SELECT THE DATABASE
--------------------------------------------------------- */

USE parks_and_recreation;


/* ---------------------------------------------------------
   2. EXPLORE THE EMPLOYEE DATA
--------------------------------------------------------- */

SELECT *
FROM employee_demographics;

SELECT *
FROM employee_salary;


/* ---------------------------------------------------------
   3. CHECK THE NUMBER OF EMPLOYEES
--------------------------------------------------------- */

SELECT COUNT(*) AS total_employees
FROM employee_demographics;


/* ---------------------------------------------------------
   4. CHECK EMPLOYEE DEMOGRAPHICS
--------------------------------------------------------- */

SELECT
    gender,
    COUNT(*) AS employee_count
FROM employee_demographics
GROUP BY gender
ORDER BY employee_count DESC;


/* ---------------------------------------------------------
   5. ANALYZE EMPLOYEE AGE
--------------------------------------------------------- */

SELECT
    employee_id,
    first_name,
    last_name,
    birth_date,
    TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS calculated_age
FROM employee_demographics
ORDER BY calculated_age DESC;


/* ---------------------------------------------------------
   6. CREATE AGE GROUPS
--------------------------------------------------------- */

SELECT
    employee_id,
    first_name,
    last_name,
    TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) AS calculated_age,
    CASE
        WHEN TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) < 25
            THEN 'Under 25'
        WHEN TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) BETWEEN 25 AND 34
            THEN '25-34'
        WHEN TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) BETWEEN 35 AND 44
            THEN '35-44'
        WHEN TIMESTAMPDIFF(YEAR, birth_date, CURDATE()) BETWEEN 45 AND 54
            THEN '45-54'
        ELSE '55+'
    END AS age_group
FROM employee_demographics;


/* ---------------------------------------------------------
   7. ANALYZE OCCUPATIONS
--------------------------------------------------------- */

SELECT
    occupation,
    COUNT(*) AS employee_count
FROM employee_salary
GROUP BY occupation
ORDER BY employee_count DESC;


/* ---------------------------------------------------------
   8. ANALYZE DEPARTMENT DISTRIBUTION
--------------------------------------------------------- */

SELECT
    d.department_name,
    COUNT(*) AS employee_count
FROM employee_salary s
JOIN parks_departments d
    ON s.dept_id = d.department_id
GROUP BY d.department_name
ORDER BY employee_count DESC;


/* ---------------------------------------------------------
   9. SALARY STATISTICS
--------------------------------------------------------- */

SELECT
    COUNT(*) AS total_employees,
    MIN(salary) AS minimum_salary,
    MAX(salary) AS maximum_salary,
    ROUND(AVG(salary), 2) AS average_salary,
    ROUND(SUM(salary), 2) AS total_payroll
FROM employee_salary;


/* ---------------------------------------------------------
   10. SALARY BY OCCUPATION
--------------------------------------------------------- */

SELECT
    occupation,
    COUNT(*) AS employee_count,
    ROUND(AVG(salary), 2) AS average_salary,
    MIN(salary) AS minimum_salary,
    MAX(salary) AS maximum_salary
FROM employee_salary
GROUP BY occupation
ORDER BY average_salary DESC;


/* ---------------------------------------------------------
   11. SALARY BY DEPARTMENT
--------------------------------------------------------- */

SELECT
    d.department_name,
    COUNT(*) AS employee_count,
    ROUND(AVG(s.salary), 2) AS average_salary,
    MIN(s.salary) AS minimum_salary,
    MAX(s.salary) AS maximum_salary
FROM employee_salary s
JOIN parks_departments d
    ON s.dept_id = d.department_id
GROUP BY d.department_name
ORDER BY average_salary DESC;


/* ---------------------------------------------------------
   12. CREATE SALARY BANDS
--------------------------------------------------------- */

SELECT
    employee_id,
    salary,
    CASE
        WHEN salary < 50000 THEN 'Below 50K'
        WHEN salary BETWEEN 50000 AND 74999 THEN '50K-74K'
        WHEN salary BETWEEN 75000 AND 99999 THEN '75K-99K'
        WHEN salary BETWEEN 100000 AND 149999 THEN '100K-149K'
        ELSE '150K+'
    END AS salary_band
FROM employee_salary
ORDER BY salary DESC;


/* ---------------------------------------------------------
   13. COMPARE EMPLOYEE SALARY WITH DEPARTMENT AVERAGE
--------------------------------------------------------- */

SELECT
    s.employee_id,
    s.salary,
    d.department_name,
    ROUND(
        AVG(s.salary) OVER (
            PARTITION BY s.dept_id
        ), 2
    ) AS department_average_salary,
    ROUND(
        s.salary -
        AVG(s.salary) OVER (
            PARTITION BY s.dept_id
        ), 2
    ) AS difference_from_department_average
FROM employee_salary s
JOIN parks_departments d
    ON s.dept_id = d.department_id
ORDER BY difference_from_department_average DESC;


/* ---------------------------------------------------------
   14. CREATE EMPLOYEE ANALYTICS VIEW
--------------------------------------------------------- */

CREATE OR REPLACE VIEW employee_analytics AS

SELECT
    d.employee_id,
    CONCAT(d.first_name, ' ', d.last_name) AS full_name,
    d.birth_date,
    TIMESTAMPDIFF(YEAR, d.birth_date, CURDATE()) AS calculated_age,
    d.gender,
    s.salary,
    s.occupation,
    pd.department_name,

    CASE
        WHEN TIMESTAMPDIFF(YEAR, d.birth_date, CURDATE()) < 25
            THEN 'Under 25'
        WHEN TIMESTAMPDIFF(YEAR, d.birth_date, CURDATE()) BETWEEN 25 AND 34
            THEN '25-34'
        WHEN TIMESTAMPDIFF(YEAR, d.birth_date, CURDATE()) BETWEEN 35 AND 44
            THEN '35-44'
        WHEN TIMESTAMPDIFF(YEAR, d.birth_date, CURDATE()) BETWEEN 45 AND 54
            THEN '45-54'
        ELSE '55+'
    END AS age_group,

    CASE
        WHEN s.salary < 50000 THEN 'Below 50K'
        WHEN s.salary BETWEEN 50000 AND 74999 THEN '50K-74K'
        WHEN s.salary BETWEEN 75000 AND 99999 THEN '75K-99K'
        WHEN s.salary BETWEEN 100000 AND 149999 THEN '100K-149K'
        ELSE '150K+'
    END AS salary_band,

    ROUND(
        AVG(s.salary) OVER (
            PARTITION BY s.dept_id
        ), 2
    ) AS dept_avg_salary,

    ROUND(
        s.salary -
        AVG(s.salary) OVER (
            PARTITION BY s.dept_id
        ), 2
    ) AS diff_from_dept_avg

FROM employee_demographics d
JOIN employee_salary s
    ON d.employee_id = s.employee_id
JOIN parks_departments pd
    ON s.dept_id = pd.department_id;


/* ---------------------------------------------------------
   15. VIEW THE FINAL ANALYTICS DATASET
--------------------------------------------------------- */

SELECT *
FROM employee_analytics;


/* ---------------------------------------------------------
   16. IDENTIFY EMPLOYEES ABOVE THEIR DEPARTMENT AVERAGE
--------------------------------------------------------- */

SELECT
    full_name,
    department_name,
    salary,
    dept_avg_salary,
    diff_from_dept_avg
FROM employee_analytics
WHERE salary > dept_avg_salary
ORDER BY diff_from_dept_avg DESC;


/* ---------------------------------------------------------
   17. IDENTIFY EMPLOYEES BELOW THEIR DEPARTMENT AVERAGE
--------------------------------------------------------- */

SELECT
    full_name,
    department_name,
    salary,
    dept_avg_salary,
    diff_from_dept_avg
FROM employee_analytics
WHERE salary < dept_avg_salary
ORDER BY diff_from_dept_avg ASC;
