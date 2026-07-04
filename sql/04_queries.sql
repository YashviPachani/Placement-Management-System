-- ============================================================
-- Analytical Queries
-- Organized: Basic -> Joins -> Aggregations -> Advanced (CTE/Window)
-- ============================================================

-- ===================== BASIC =====================

-- Q1: Find all female students
SELECT S_Name, Email_ID, Branch
FROM Student
WHERE Gender = 'Female';

-- Q2: Students with CPI greater than 8.0
SELECT S_Name, Branch, CPI
FROM Student
WHERE CPI > 8.0
ORDER BY CPI DESC;

-- Q3: Count total number of companies
SELECT COUNT(*) AS Total_Companies FROM Company;

-- Q4: List all active (ongoing/upcoming) drives
SELECT Drive_ID, Drive_Start_Date, Drive_Status
FROM Drive
WHERE Drive_Status IN ('Ongoing', 'Upcoming');

-- Q5: Alumni currently working at a specific company
SELECT S_ID, Current_Job_Title FROM Alumni WHERE Current_Company = 'Google';

-- Q6: Students who graduated in 2024
SELECT S_Name, Branch, Graduation_Year FROM Student WHERE Graduation_Year = 2024;

--CHECK THIS ONE
-- Q7: Companies in the 'Technology' industry
SELECT C_Name, Website, Location FROM Company WHERE Industry_Type = 'Technology';

-- Q8: Job roles with CTC greater than 10 LPA
SELECT Job_Role_ID, Avg_CTC_or_Stipend, Deadline
FROM Job_Role
WHERE Avg_CTC_or_Stipend > 1000000;


-- ===================== AGGREGATIONS =====================

-- Q9: Average CPI by branch and graduation year
SELECT Branch, Graduation_Year, AVG(CPI) AS Avg_CPI
FROM Student
WHERE CPI IS NOT NULL
GROUP BY Branch, Graduation_Year
ORDER BY Branch, Graduation_Year;

-- Q10: Count students by branch
SELECT Branch, COUNT(*) AS Student_Count
FROM Student
GROUP BY Branch
ORDER BY Student_Count DESC;

-- Q11: Drives with average CTC > 10 LPA
SELECT d.Drive_ID, AVG(j.Avg_CTC_or_Stipend) AS Avg_CTC
FROM Drive d
JOIN Job_Role j ON d.Drive_ID = j.Drive_ID
GROUP BY d.Drive_ID
HAVING AVG(j.Avg_CTC_or_Stipend) > 1000000;


-- ===================== JOINS =====================

-- Q12: Placement coordinators with student names
SELECT pc.PC_ID, s.S_Name, pc.Role
FROM Placement_Coordinators pc
JOIN Student s ON pc.S_ID = s.S_ID;

-- Q13: Job roles with their company names
SELECT jr.Job_Role_ID, c.C_Name, jr.Avg_CTC_or_Stipend
FROM Job_Role jr
JOIN Company c ON jr.C_ID = c.C_ID;

-- Q14: Job roles with academic eligibility criteria
SELECT jr.Job_Role_ID, jrae.Branch_name, jrae.Min_CPI_Required
FROM Job_Role jr
JOIN Job_Role_Academic_Eligibility jrae ON jr.Job_Role_ID = jrae.Job_Role_ID;

-- Q15: Students, their resumes, and applications
SELECT s.S_Name,s.Branch,sr.resume_id,a.Application_Status
FROM Student s
JOIN Student_Resume sr
    ON s.S_ID = sr.student_id
JOIN Application a
    ON sr.resume_id = a.Resume_ID;

-- Q16: Companies assigned to placement coordinators
SELECT c.C_Name, pc.PC_ID, pc.Role
FROM Company_Assigned ca
JOIN Company c ON ca.C_ID = c.C_ID
JOIN Placement_Coordinators pc ON ca.PC_ID = pc.PC_ID;

-- Q17: Job roles with company and drive information
SELECT jr.Job_Role_ID, c.C_Name, d.Drive_Start_Date, jr.Avg_CTC_or_Stipend
FROM Job_Role jr
JOIN Company c ON jr.C_ID = c.C_ID
JOIN Drive d ON jr.Drive_ID = d.Drive_ID;

-- Q18: Students who registered for drives but are not interested
SELECT s.S_Name, r.Reason_If_Not_Interested
FROM Student s
JOIN register r ON s.S_ID = r.S_ID
WHERE r.Is_Interested = FALSE;

-- Q19: Job roles with their required skills and locations
SELECT jr.Job_Role_ID, js.Skill_Name, jl.Location
FROM Job_Role jr
LEFT JOIN Job_Role_Skill_Requirement js ON jr.Job_Role_ID = js.Job_Role_ID
LEFT JOIN Job_Role_Location jl ON jr.Job_Role_ID = jl.Job_Role_ID;

-- Q20: Eligible students for each job role based on branch and CPI
SELECT s.S_Name, s.Branch, s.CPI, jr.Job_Role_ID, c.C_Name
FROM Student s
JOIN Job_Role_Academic_Eligibility jrae ON s.Branch = jrae.Branch_name
JOIN Job_Role jr ON jrae.Job_Role_ID = jr.Job_Role_ID
JOIN Company c ON jr.C_ID = c.C_ID
WHERE s.CPI >= jrae.Min_CPI_Required;

-- Q21: Students with latest resume version who applied for jobs
SELECT s.S_Name, sr.Resume_ID, sr.Version_Number, jr.Job_Role_ID, a.Application_Status
FROM Student s
JOIN Student_Resume sr ON s.S_ID = sr.student_id
JOIN Application a ON sr.Resume_ID = a.Resume_ID
JOIN Job_Role jr ON a.Job_Role_ID = jr.Job_Role_ID
WHERE sr.Version_Number = (
    SELECT MAX(Version_Number) FROM Student_Resume WHERE S_ID = s.S_ID
);

-- Q22: Students who registered but didn't apply to any job
SELECT s.S_Name, s.Branch, r.Registration_Date, d.Drive_ID
FROM Student s
JOIN register r ON s.S_ID = r.S_ID
JOIN Drive d ON r.Drive_ID = d.Drive_ID
LEFT JOIN Application a ON r.Register_ID = a.Register_ID
WHERE a.Application_ID IS NULL;

-- Q23: All applications with eligibility verification
SELECT s.S_Name, s.Branch, s.CPI, c.C_Name, jr.Job_Role_ID,
       jrae.Min_CPI_Required, a.Application_Status,
       CASE WHEN s.CPI >= jrae.Min_CPI_Required THEN 'Eligible' ELSE 'Not Eligible' END AS Eligibility_Status
FROM Application a
JOIN register r ON a.Register_ID = r.Register_ID
JOIN Student s ON r.S_ID = s.S_ID
JOIN Job_Role jr ON a.Job_Role_ID = jr.Job_Role_ID
JOIN Company c ON jr.C_ID = c.C_ID
JOIN Job_Role_Academic_Eligibility jrae
     ON jr.Job_Role_ID = jrae.Job_Role_ID AND s.Branch = jrae.Branch_name;


-- ===================== ADVANCED: CTE / WINDOW FUNCTIONS =====================

-- Q24: Top 5 companies by average package with application statistics
WITH CompanyStats AS (
    SELECT c.C_ID, c.C_Name,
           AVG(jr.Avg_CTC_or_Stipend) AS Avg_Package,
           COUNT(DISTINCT jr.Job_Role_ID) AS Job_Roles,
           COUNT(DISTINCT a.Application_ID) AS Total_Applications,
           COUNT(DISTINCT CASE WHEN a.Application_Status = 'Selected' THEN a.Application_ID END) AS Selected_Count
    FROM Company c
    JOIN Job_Role jr ON c.C_ID = jr.C_ID
    LEFT JOIN Application a ON jr.Job_Role_ID = a.Job_Role_ID
    GROUP BY c.C_ID, c.C_Name
)
SELECT C_Name, Avg_Package, Job_Roles, Total_Applications, Selected_Count,
       CASE WHEN Total_Applications > 0
            THEN ROUND(100.0 * Selected_Count / Total_Applications, 2)
            ELSE 0 END AS Selection_Rate
FROM CompanyStats
ORDER BY Avg_Package DESC
LIMIT 5;

-- Q25: Rank students by applications and success rate (per branch)
WITH StudentApplications AS (
    SELECT s.S_ID, s.S_Name, s.Branch, s.CPI,
           COUNT(a.Application_ID) AS Total_Apps,
           COUNT(CASE WHEN a.Application_Status = 'Selected' THEN 1 END) AS Selected_Apps,
           COUNT(CASE WHEN a.Application_Status = 'Interviewed' THEN 1 END) AS Interview_Apps
    FROM Student s
    JOIN register r ON s.S_ID = r.S_ID
    JOIN Application a ON r.Register_ID = a.Register_ID
    GROUP BY s.S_ID, s.S_Name, s.Branch, s.CPI
)
SELECT S_Name, Branch, CPI, Total_Apps, Selected_Apps, Interview_Apps,
       CASE WHEN Total_Apps > 0 THEN ROUND(100.0 * Selected_Apps / Total_Apps, 2) ELSE 0 END AS Success_Rate,
       RANK() OVER (PARTITION BY Branch ORDER BY Selected_Apps DESC, CPI DESC) AS Branch_Rank
FROM StudentApplications
WHERE Total_Apps > 0
ORDER BY Success_Rate DESC, Total_Apps DESC;

-- Q26: Placement success rate by branch
SELECT s.Branch,
       COUNT(DISTINCT CASE WHEN a.Application_Status = 'Selected' THEN s.S_ID END) AS Placed_Students,
       COUNT(DISTINCT s.S_ID) AS Total_Students,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN a.Application_Status = 'Selected' THEN s.S_ID END) /
             COUNT(DISTINCT s.S_ID), 2) AS Placement_Percentage
FROM Student s
LEFT JOIN register r ON s.S_ID = r.S_ID
LEFT JOIN Application a ON r.Register_ID = a.Register_ID
GROUP BY s.Branch
ORDER BY Placement_Percentage DESC;

-- Q27: Drives with more than 10 registered students
SELECT d.Drive_ID, COUNT(r.S_ID) AS Registered_Students
FROM Drive d
JOIN registers r ON d.Drive_ID = r.Drive_ID
GROUP BY d.Drive_ID
HAVING COUNT(r.S_ID) > 10;

-- Q28: Students with multiple selections (best offer + all offers)
WITH StudentSelections AS (
    SELECT s.S_ID, s.S_Name, s.Branch, jr.Job_Role_ID, c.C_Name, jr.Avg_CTC_or_Stipend,
           ROW_NUMBER() OVER (PARTITION BY s.S_ID ORDER BY jr.Avg_CTC_or_Stipend DESC) AS selection_rank
    FROM Student s
    JOIN register r ON s.S_ID = r.S_ID
    JOIN Application a ON r.Register_ID = a.Register_ID
    JOIN Job_Role jr ON a.Job_Role_ID = jr.Job_Role_ID
    JOIN Company c ON jr.C_ID = c.C_ID
    WHERE a.Application_Status = 'Selected'
)
SELECT S_Name, Branch,
       MAX(CASE WHEN selection_rank = 1 THEN C_Name END) AS Best_Offer_Company,
       MAX(CASE WHEN selection_rank = 1 THEN Avg_CTC_or_Stipend END) AS Best_Package,
       COUNT(*) AS Total_Selections,
       STRING_AGG(C_Name, ', ' ORDER BY Avg_CTC_or_Stipend DESC) AS All_Companies
FROM StudentSelections
GROUP BY S_ID, S_Name, Branch
HAVING COUNT(*) > 1
ORDER BY Best_Package DESC;

-- Q29: Correlation between CPI range and placement package
WITH StudentPlacements AS (
    SELECT s.S_ID, s.S_Name, s.Branch, s.CPI,
           MAX(jr.Avg_CTC_or_Stipend) AS Best_Package,
           AVG(jr.Avg_CTC_or_Stipend) AS Avg_Offered_Package,
           COUNT(DISTINCT a.Application_ID) AS Applications
    FROM Student s
    JOIN register r ON s.S_ID = r.S_ID
    JOIN Application a ON r.Register_ID = a.Register_ID
    JOIN Job_Role jr ON a.Job_Role_ID = jr.Job_Role_ID
    WHERE a.Application_Status = 'Selected'
    GROUP BY s.S_ID, s.S_Name, s.Branch, s.CPI
)
SELECT
    CASE WHEN CPI >= 9.0 THEN '9.0-10.0'
         WHEN CPI >= 8.0 THEN '8.0-8.9'
         WHEN CPI >= 7.0 THEN '7.0-7.9'
         ELSE 'Below 7.0' END AS CPI_Range,
    COUNT(*) AS Students,
    ROUND(AVG(Best_Package), 2) AS Avg_Best_Package,
    ROUND(MIN(Best_Package), 2) AS Min_Package,
    ROUND(MAX(Best_Package), 2) AS Max_Package,
    ROUND(AVG(Applications), 2) AS Avg_Applications
FROM StudentPlacements
GROUP BY CPI_Range
ORDER BY CPI_Range DESC;

-- Q30: Comparative branch analysis with placement %, package stats, and rankings
WITH branch_stats AS (
    SELECT
        s.Branch,
        COUNT(DISTINCT s.S_ID) AS total_students,
        AVG(s.CPI) AS avg_cpi,
        COUNT(DISTINCT CASE WHEN a.Application_Status = 'Selected' THEN s.S_ID END) AS placed_students,
        AVG(jr.Avg_CTC_or_Stipend) AS avg_package_offered,
        MAX(jr.Avg_CTC_or_Stipend) AS highest_package,
        COUNT(DISTINCT jr.C_ID) AS companies_interested
    FROM Student s
    LEFT JOIN register r ON s.S_ID = r.S_ID
    LEFT JOIN Application a ON r.Register_ID = a.Register_ID
    LEFT JOIN Job_Role jr ON a.Job_Role_ID = jr.Job_Role_ID
    WHERE s.Status = 'Active'
    GROUP BY s.Branch
),
branch_rankings AS (
    SELECT *,
           RANK() OVER (ORDER BY avg_package_offered DESC) AS package_rank,
           RANK() OVER (ORDER BY avg_cpi DESC) AS cpi_rank
    FROM branch_stats
)
SELECT Branch, total_students, ROUND(avg_cpi, 2) AS avg_cpi, placed_students,
       ROUND(placed_students::NUMERIC / total_students * 100, 2) AS placement_percentage,
       ROUND(avg_package_offered, 2) AS avg_package_lpa,
       ROUND(highest_package, 2) AS highest_package_lpa,
       companies_interested
FROM branch_rankings;

-- Q31: Skill gap analysis - demand vs. selection success vs. package
WITH skill_demand AS (
    SELECT jrsr.Skill_Name,
           COUNT(DISTINCT jrsr.Job_Role_ID) AS roles_requiring_skill,
           COUNT(DISTINCT a.Application_ID) AS applications_for_skill,
           COUNT(DISTINCT CASE WHEN a.Application_Status = 'Selected' THEN a.Application_ID END) AS selections_with_skill,
           AVG(jr.Avg_CTC_or_Stipend) AS avg_package_for_skill,
           COUNT(DISTINCT jr.C_ID) AS companies_seeking_skill
    FROM Job_Role_Skill_Requirement jrsr
    JOIN Job_Role jr ON jrsr.Job_Role_ID = jr.Job_Role_ID
    LEFT JOIN Application a ON jr.Job_Role_ID = a.Job_Role_ID
    GROUP BY jrsr.Skill_Name
)
SELECT Skill_Name, roles_requiring_skill, companies_seeking_skill,
       applications_for_skill, selections_with_skill,
       ROUND(selections_with_skill::NUMERIC / NULLIF(applications_for_skill, 0) * 100, 2) AS success_rate_percentage,
       ROUND(avg_package_for_skill, 2) AS avg_package_lpa,
       CASE WHEN roles_requiring_skill >= 10 THEN 'Critical Skill'
            WHEN roles_requiring_skill >= 5 THEN 'High Demand'
            WHEN roles_requiring_skill >= 2 THEN 'Moderate Demand'
            ELSE 'Niche Skill' END AS demand_category,
       ROUND(roles_requiring_skill * avg_package_for_skill, 2) AS skill_market_value
FROM skill_demand
WHERE roles_requiring_skill > 0
ORDER BY skill_market_value DESC, roles_requiring_skill DESC
LIMIT 20;
