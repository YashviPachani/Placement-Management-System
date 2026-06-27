-- ============================================================
-- Triggers
-- ============================================================

-- 1. Prevent a student from applying to the same job role more than once
CREATE OR REPLACE FUNCTION prevent_duplicate_application() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM Application a
        JOIN registers r ON a.Register_ID = r.Register_ID
        WHERE r.Register_ID = NEW.Register_ID AND a.Job_Role_ID = NEW.Job_Role_ID
    ) THEN
        RAISE EXCEPTION 'Student has already applied for this job role (Register ID: %, Job Role ID: %)',
            NEW.Register_ID, NEW.Job_Role_ID;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_duplicate_application
BEFORE INSERT ON Application
FOR EACH ROW
EXECUTE FUNCTION prevent_duplicate_application();


-- 2. Update a company's Last_Visit_Year whenever a new drive involving them starts
CREATE OR REPLACE FUNCTION update_company_last_visit() RETURNS TRIGGER AS $$
BEGIN
    UPDATE Company
    SET Last_Visit_Year = EXTRACT(YEAR FROM NEW.Drive_Start_Date)
    WHERE C_ID IN (
        SELECT DISTINCT C_ID FROM Job_Role WHERE Drive_ID = NEW.Drive_ID
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_company_last_visit
AFTER INSERT ON Drive
FOR EACH ROW
EXECUTE FUNCTION update_company_last_visit();


-- 3. Validate eligibility before allowing an application
CREATE OR REPLACE FUNCTION validate_application_eligibility() RETURNS TRIGGER AS $$
DECLARE
    v_s_id VARCHAR(10);
    v_is_eligible BOOLEAN;
BEGIN
    SELECT r.S_ID INTO v_s_id FROM registers r WHERE r.Register_ID = NEW.Register_ID;
    v_is_eligible := check_student_eligibility(v_s_id, NEW.Job_Role_ID);

    IF NOT v_is_eligible THEN
        RAISE EXCEPTION 'Student does not meet eligibility criteria for this job role';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_application_eligibility
BEFORE INSERT ON Application
FOR EACH ROW
EXECUTE FUNCTION validate_application_eligibility();


-- 4. Automatically create an Alumni record when a student's status changes to 'Graduated'
CREATE OR REPLACE FUNCTION insert_alumni() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Status = 'Graduated' THEN
        INSERT INTO Alumni (S_ID, Current_Job_Title, Current_Company)
        VALUES (NEW.S_ID, 'Not Updated', 'Not Updated');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_alumni_insert
AFTER UPDATE ON Student
FOR EACH ROW
EXECUTE FUNCTION insert_alumni();
