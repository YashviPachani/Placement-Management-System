-- ============================================================
-- Stored Functions
-- ============================================================

-- F1: Returns TRUE/FALSE based on whether a student meets the minimum CPI for a job role
CREATE FUNCTION check_student_eligibility(
    p_student_id VARCHAR,
    p_job_role_id VARCHAR
)
RETURNS BOOLEAN AS $$
DECLARE
    v_student_cpi NUMERIC(3,2);
    v_min_cpi NUMERIC(3,2);
BEGIN
    SELECT s.CPI
    INTO v_student_cpi
    FROM Student s
    WHERE s.S_ID = p_student_id;

    SELECT jrae.Min_CPI_Required
    INTO v_min_cpi
    FROM Job_Role_Academic_Eligibility jrae
    WHERE jrae.Job_Role_ID = p_job_role_id;

    IF v_min_cpi IS NULL OR v_student_cpi >= v_min_cpi THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;



-- F2: Calculates the overall placement percentage for a given branch
CREATE OR REPLACE FUNCTION calculate_placement_rate(branch_name VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    v_placed_count INT;
    v_total_students INT;
BEGIN
    SELECT COUNT(DISTINCT s.S_ID) INTO v_total_students FROM Student s WHERE s.Branch = branch_name;

    SELECT COUNT(DISTINCT s.S_ID) INTO v_placed_count
    FROM Student s
    JOIN register r ON s.S_ID = r.S_ID
    JOIN Application a ON r.Register_ID = a.Register_ID
    WHERE s.Branch = branch_name AND a.Application_Status = 'Selected';

    IF v_total_students = 0 THEN
        RETURN 0.00;
    ELSE
        RETURN ROUND((v_placed_count::NUMERIC / v_total_students) * 100, 2);
    END IF;
END;
$$ LANGUAGE plpgsql;


-- F3: Returns the average CTC/Stipend offered across all job roles in a specific drive
CREATE OR REPLACE FUNCTION get_drive_avg_package(drive_id VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    v_avg_ctc NUMERIC;
BEGIN
    SELECT AVG(Avg_CTC_or_Stipend) INTO v_avg_ctc FROM Job_Role WHERE Drive_ID = drive_id;
    RETURN COALESCE(v_avg_ctc, 0);
END;
$$ LANGUAGE plpgsql;


-- F4: Returns the name of the primary mentor for a given student ID
CREATE OR REPLACE FUNCTION get_student_mentor_name(student_id VARCHAR)
RETURNS VARCHAR AS $$
DECLARE
    v_mentor_name VARCHAR(100);
BEGIN
    SELECT m.Mentor_Name INTO v_mentor_name
    FROM Mentor_Student ms
    JOIN Mentors m ON ms.Mentor_ID = m.Mentor_ID
    WHERE ms.S_ID = student_id
    LIMIT 1;
    RETURN COALESCE(v_mentor_name, 'No Mentor Assigned');
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- Stored Procedures
-- ============================================================

-- P1: Increments a company's Last_Hired_Count when a student is selected
CREATE OR REPLACE PROCEDURE increment_hired_count(cid VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE Company SET Last_Hired_Count = COALESCE(Last_Hired_Count, 0) + 1 WHERE C_ID = cid;
END;
$$;

-- P2: Changes the status of past drives to 'Completed'
CREATE OR REPLACE PROCEDURE update_drive_status()
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE Drive
    SET Drive_Status = 'Completed'
    WHERE Drive_End_Date < CURRENT_DATE AND Drive_Status != 'Completed';
END;
$$;


-- P3: Marks all other applications as 'Rejected' for a student once one is 'Selected'
CREATE OR REPLACE PROCEDURE process_application_selection(selected_app_id INT)
LANGUAGE plpgsql AS $$
DECLARE
    v_s_id VARCHAR(10);
BEGIN
    SELECT r.S_ID INTO v_s_id
    FROM Application a
    JOIN register r ON a.Register_ID = r.Register_ID
    WHERE a.Application_ID = selected_app_id;

    UPDATE Application
    SET Application_Status = 'Rejected'
    WHERE Register_ID IN (SELECT Register_ID FROM register WHERE S_ID = v_s_id)
      AND Application_Status != 'Selected'
      AND Application_ID != selected_app_id;
END;
$$;

-- P4: Inserts a new job role, ensuring the company and drive exist
CREATE OR REPLACE PROCEDURE add_new_job_role(jrid VARCHAR, driveid INT, cid VARCHAR, ctc NUMERIC)
LANGUAGE plpgsql AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Company WHERE C_ID = cid)
       OR NOT EXISTS (SELECT 1 FROM Drive WHERE Drive_ID = driveid) THEN
        RAISE EXCEPTION 'Company or Drive ID does not exist.';
    END IF;

    INSERT INTO Job_Role (Job_Role_ID, Drive_ID, C_ID, Avg_CTC_or_Stipend)
    VALUES (jrid, driveid, cid, ctc);
END;
$$;

-- P5: Updates a student's Status to 'Placed' if they have a 'Selected' application
CREATE OR REPLACE PROCEDURE update_student_status_to_placed(student_id VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE Student
    SET Status = 'Placed'
    WHERE S_ID = student_id AND EXISTS (
        SELECT 1 FROM Application a
        JOIN register r ON a.Register_ID = r.Register_ID
        WHERE r.S_ID = student_id AND a.Application_Status = 'Selected'
    );
END;
$$;
