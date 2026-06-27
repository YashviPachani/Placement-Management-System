-- ============================================================
-- Placement Management System - Schema (DDL)
-- NOTE: This is the initial schema pulled from the SRS document.
-- Known issues being fixed in a follow-up pass (see README status):
--   - Table creation order / forward references
--   - A few missing closing parentheses
--   - Type mismatches between PK and FK columns (e.g. Drive_ID)
-- ============================================================

CREATE TABLE Student (
    S_ID VARCHAR(10) PRIMARY KEY,
    S_Name VARCHAR(100) NOT NULL,
    Email_ID VARCHAR(100) UNIQUE NOT NULL,
    DOB DATE NOT NULL,
    Gender VARCHAR(10) CHECK (Gender IN ('Male', 'Female', 'Other')),
    Admission_Year INT NOT NULL,
    Branch VARCHAR(50) NOT NULL,
    Graduation_Year INT,
    Status VARCHAR(20) CHECK (Status IN ('Active', 'Graduated', 'Dropped')) NOT NULL,
    CPI NUMERIC(3, 2),
    Nationality VARCHAR(50) CHECK (Nationality IN ('Indian', 'Foreign')) NOT NULL,
    Disability_Status VARCHAR(10) CHECK (Disability_Status IN ('Yes', 'None'))
);

CREATE TABLE Student_Phone (
    S_ID VARCHAR(10) NOT NULL,
    Phone_No1 VARCHAR(15) NOT NULL,
    Phone_No2 VARCHAR(15),
    PRIMARY KEY (S_ID),
    FOREIGN KEY (S_ID) REFERENCES Student(S_ID) ON DELETE CASCADE
);

CREATE TABLE Alumni (
    S_ID VARCHAR(10) PRIMARY KEY,
    Current_Job_Title VARCHAR(100) NOT NULL,
    Current_Company VARCHAR(100) NOT NULL,
    Current_Location VARCHAR(100),
    Highest_Degree_Achieved VARCHAR(50),
    Company_History TEXT,
    LinkedIn_Profile VARCHAR(255),
    CONSTRAINT fk_alumni_student FOREIGN KEY (S_ID) REFERENCES Student(S_ID) ON DELETE CASCADE
);

CREATE TABLE Company (
    C_ID VARCHAR(10) PRIMARY KEY,
    C_Name VARCHAR(255) NOT NULL,
    Website VARCHAR(255),
    Industry_Type VARCHAR(100),
    Location VARCHAR(255),
    Email VARCHAR(100) UNIQUE,
    Year_Founded INT,
    Last_Visit_Year INT,
    Last_Hired_Count INT
);

CREATE TABLE Drive (
    Drive_ID SERIAL PRIMARY KEY,
    Drive_Start_Date DATE NOT NULL,
    Drive_End_Date DATE,
    Drive_Status VARCHAR(20) DEFAULT 'Upcoming' CHECK (Drive_Status IN ('Upcoming', 'Ongoing', 'Completed'))
);

CREATE TABLE Drive_log (
    Drive_ID INT NOT NULL,
    Drive_type VARCHAR(100) UNIQUE NOT NULL,
    FOREIGN KEY (Drive_ID) REFERENCES Drive(Drive_ID) ON DELETE CASCADE
);

CREATE TABLE Drive_Eligibility (
    Drive_ID INT NOT NULL REFERENCES Drive(Drive_ID) ON DELETE CASCADE,
    Batch_Eligible VARCHAR(20) NOT NULL,
    Batch_year_Eligible VARCHAR(4) NOT NULL,
    PRIMARY KEY (Drive_ID, Batch_Eligible)
);

CREATE TABLE Job_Role (
    Job_Role_ID VARCHAR(10) PRIMARY KEY,
    C_ID VARCHAR(10) NOT NULL REFERENCES Company(C_ID) ON DELETE CASCADE,
    Drive_ID INT NOT NULL REFERENCES Drive(Drive_ID) ON DELETE CASCADE,
    Avg_CTC_or_Stipend NUMERIC(10,2),
    Deadline DATE
);

CREATE TABLE Job_Role_Academic_Eligibility (
    Job_Role_ID VARCHAR(10) NOT NULL REFERENCES Job_Role(Job_Role_ID) ON DELETE CASCADE,
    Branch_name VARCHAR(15) NOT NULL,
    Min_CPI_Required NUMERIC(3, 2) NOT NULL,
    PRIMARY KEY (Job_Role_ID, Branch_name)
);

CREATE TABLE Job_Role_Skill_Requirement (
    Job_Role_ID VARCHAR(10) NOT NULL REFERENCES Job_Role(Job_Role_ID) ON DELETE CASCADE,
    Skill_Name VARCHAR(50) NOT NULL,
    PRIMARY KEY (Job_Role_ID, Skill_Name)
);

CREATE TABLE Job_Role_Location (
    Job_Role_ID VARCHAR(10) REFERENCES Job_Role(Job_Role_ID) ON DELETE CASCADE,
    Location VARCHAR(100) NOT NULL,
    PRIMARY KEY (Job_Role_ID, Location)
);

CREATE TABLE Student_Resume (
    Resume_ID VARCHAR(10) NOT NULL,
    S_ID VARCHAR(10) NOT NULL REFERENCES Student(S_ID) ON DELETE CASCADE,
    Resume_File_Path VARCHAR(255) NOT NULL,
    Upload_Date DATE NOT NULL,
    Version_Number INT NOT NULL,
    PRIMARY KEY (Resume_ID, S_ID)
);

CREATE TABLE registers (
    Register_ID SERIAL PRIMARY KEY,
    S_ID VARCHAR(10) REFERENCES Student(S_ID) ON DELETE CASCADE,
    Drive_ID INT REFERENCES Drive(Drive_ID) ON DELETE CASCADE,
    Registration_Date DATE,
    Is_Interested BOOLEAN DEFAULT TRUE,
    Reason_If_Not_Interested TEXT,
    CONSTRAINT registers_unique UNIQUE (S_ID, Drive_ID)
);

CREATE TABLE Application (
    Application_ID SERIAL PRIMARY KEY,
    Register_ID INT REFERENCES registers(Register_ID) ON DELETE CASCADE,
    Job_Role_ID VARCHAR(10) REFERENCES Job_Role(Job_Role_ID) ON DELETE CASCADE,
    Resume_ID VARCHAR(10) REFERENCES Student_Resume(Resume_ID),
    Application_Status VARCHAR(20) CHECK (Application_Status IN
        ('Applied', 'Shortlisted', 'Interviewed', 'Selected', 'Rejected')),
    CONSTRAINT application_unique UNIQUE (Register_ID, Job_Role_ID)
);

CREATE TABLE Selection_Round (
    Round_ID SERIAL PRIMARY KEY,
    Job_Role_ID VARCHAR(10) REFERENCES Job_Role(Job_Role_ID) ON DELETE CASCADE,
    Round_Number INT NOT NULL,
    Round_Type VARCHAR(50) NOT NULL CHECK (Round_Type IN
        ('Aptitude Test', 'Technical Test', 'Technical Interview', 'HR Interview', 'Case Study', 'Coding Test')),
    Duration_Minutes INT,
    Cutoff_Score DECIMAL(5,2),
    Is_Completed BOOLEAN DEFAULT TRUE,
    UNIQUE (Job_Role_ID, Round_Number)
);

CREATE TABLE Student_Round_Result (
    Result_ID SERIAL PRIMARY KEY,
    Round_ID INT REFERENCES Selection_Round(Round_ID) ON DELETE CASCADE,
    Application_ID INT REFERENCES Application(Application_ID) ON DELETE CASCADE,
    Result VARCHAR(20) CHECK (Result IN ('Pending', 'Passed', 'Failed')),
    Score DECIMAL(5,2),
    Feedback TEXT,
    UNIQUE (Round_ID, Application_ID)
);

CREATE TABLE Offer_Letter (
    Offer_Letter_ID SERIAL PRIMARY KEY,
    S_ID VARCHAR(10) NOT NULL REFERENCES Student(S_ID) ON DELETE CASCADE,
    Job_Role_ID VARCHAR(10) NOT NULL REFERENCES Job_Role(Job_Role_ID) ON DELETE CASCADE,
    File_Path VARCHAR(500),
    File_Name VARCHAR(255),
    Date_Uploaded TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Verification_Status VARCHAR(20) DEFAULT 'Pending' CHECK (Verification_Status IN ('Pending', 'Verified', 'Rejected')),
    Reason_if_rejected TEXT,
    CONSTRAINT unique_student_job_offer UNIQUE (S_ID, Job_Role_ID)
);

CREATE TABLE Placement_Coordinators (
    PC_ID VARCHAR(10) PRIMARY KEY,
    S_ID VARCHAR(10) NOT NULL REFERENCES Student(S_ID) ON DELETE CASCADE,
    Role VARCHAR(50)
);

CREATE TABLE Company_Assigned (
    C_ID VARCHAR(10) NOT NULL REFERENCES Company(C_ID) ON DELETE CASCADE,
    PC_ID VARCHAR(10) NOT NULL REFERENCES Placement_Coordinators(PC_ID) ON DELETE CASCADE,
    PRIMARY KEY (C_ID, PC_ID)
);

CREATE TABLE Mentors (
    Mentor_ID VARCHAR(10) PRIMARY KEY,
    Mentor_Name VARCHAR(100) NOT NULL,
    Expertise VARCHAR(100)
);

CREATE TABLE Mentor_Student (
    Mentor_ID VARCHAR(10) REFERENCES Mentors(Mentor_ID) ON DELETE CASCADE,
    S_ID VARCHAR(10) REFERENCES Student(S_ID) ON DELETE CASCADE,
    PRIMARY KEY (Mentor_ID, S_ID)
);

CREATE TABLE Training (
    Training_ID VARCHAR(10) PRIMARY KEY,
    Description TEXT,
    Location VARCHAR(50),
    Duration VARCHAR(20),
    Date DATE,
    Status VARCHAR(20) CHECK (Status IN ('Completed', 'Upcoming'))
);

CREATE TABLE Student_Training (
    S_ID VARCHAR(10) NOT NULL REFERENCES Student(S_ID) ON DELETE CASCADE,
    Training_ID VARCHAR(10) NOT NULL REFERENCES Training(Training_ID) ON DELETE CASCADE,
    Feedback TEXT,
    PRIMARY KEY (S_ID, Training_ID)
);

-- ============================================================
-- TODO (next pass): verify all FK/PK type matches, add sample data,
-- and confirm every CREATE TABLE runs cleanly end-to-end.
-- ============================================================
