-- =====================================================
-- DATA QUALITY ASSESSMENT & CLEANING SCRIPT
-- Healthcare Database Analysis Project
-- =====================================================

-- *****************************************************
-- 1. DUPLICATE RECORDS IDENTIFICATION & RESOLUTION
-- *****************************************************

-- 1.1 Appointments Table - Duplicate Check
WITH duplicate_appointments AS (
    SELECT *,
           RANK() OVER (
               PARTITION BY 
                   patient_id,
                   staff_id,
                   appointment_date,
                   appointment_time,
                   appointment_type,
                   status,
                   notes,
                   created_date
           ) AS duplicate_flag
    FROM Appointments
)
SELECT * FROM duplicate_appointments 
WHERE duplicate_flag > 2;
-- RESULT: No duplicates identified

-- 1.2 Billing Table - Duplicate Check
SELECT patient_id, appointment_id, service_date, service_description FROM Billing;
SELECT DISTINCT patient_id, appointment_id, service_date, service_description FROM Billing;
-- RESULT: No duplicates identified (verified through multiple column combinations)

-- 1.3 LabResults Table - Duplicate Check
SELECT 
    patient_id,
    staff_id,
    test_date,
    test_type,
    COUNT(*) AS duplicate_count
FROM LabResults
GROUP BY 
    patient_id,
    staff_id,
    test_date,
    test_type;
-- RESULT: No duplicates identified

-- 1.4 MedicalRecords Table - Duplicate Check
SELECT *, COUNT(*) 
FROM MedicalRecords
GROUP BY patient_id, staff_id, visit_date, diagnosis, treatment, medications_prescribed
HAVING COUNT(*) > 1;
-- RESULT: No duplicates identified

-- 1.5 MedicalStaff Table - Duplicate Check
SELECT *, 
       ROW_NUMBER() OVER(PARTITION BY specialization, hire_date, department, email, phone, status) AS duplicate_flag
FROM MedicalStaff;
-- RESULT: No duplicates identified

-- 1.6 Patients Table - Duplicate Identification & Resolution
SELECT * 
FROM (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY phone, email, address, city, state, zip_code, 
                           insurance_provider, registration_date) AS duplicate_flag
    FROM Patients
) 
WHERE duplicate_flag > 1;
-- RESULT: 3 duplicate patients identified (IDs: 7, 51, 52)

-- Resolve Patient Duplicates by updating foreign key references
UPDATE Appointments SET patient_id = 1 WHERE patient_id IN (7, 51, 52);
UPDATE Billing SET patient_id = 1 WHERE patient_id IN (7, 51, 52);
UPDATE MedicalRecords SET patient_id = 1 WHERE patient_id IN (7, 51, 52);
UPDATE LabResults SET patient_id = 1 WHERE patient_id IN (7, 51, 52);

-- Remove duplicate patient records
DELETE FROM Patients WHERE patient_id IN (7, 51, 52);

-- *****************************************************
-- 2. NULL VALUE IDENTIFICATION & RESOLUTION
-- *****************************************************

-- 2.1 Appointments Table - Null Value Assessment
SELECT 
    SUM(CASE WHEN appointment_id IS NULL THEN 1 ELSE 0 END) AS appointment_id_nulls,
    SUM(CASE WHEN patient_id IS NULL THEN 1 ELSE 0 END) AS patient_id_nulls,
    SUM(CASE WHEN staff_id IS NULL THEN 1 ELSE 0 END) AS staff_id_nulls,
    SUM(CASE WHEN appointment_time IS NULL THEN 1 ELSE 0 END) AS appointment_time_nulls,
    SUM(CASE WHEN appointment_type IS NULL THEN 1 ELSE 0 END) AS appointment_type_nulls,
    SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END) AS status_nulls,
    SUM(CASE WHEN notes IS NULL THEN 1 ELSE 0 END) AS notes_nulls,
    SUM(CASE WHEN created_date IS NULL THEN 1 ELSE 0 END) AS created_date_nulls
FROM Appointments;
-- RESULT: No null values identified

-- 2.2 Billing Table - Null Value Assessment
SELECT 
    SUM(CASE WHEN appointment_id IS NULL THEN 1 ELSE 0 END) AS appointment_id_nulls,
    SUM(CASE WHEN bill_id IS NULL THEN 1 ELSE 0 END) AS bill_id_nulls,
    SUM(CASE WHEN patient_id IS NULL THEN 1 ELSE 0 END) AS patient_id_nulls,
    SUM(CASE WHEN service_date IS NULL THEN 1 ELSE 0 END) AS service_date_nulls,
    SUM(CASE WHEN service_description IS NULL THEN 1 ELSE 0 END) AS service_description_nulls,
    SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END) AS amount_nulls,
    SUM(CASE WHEN insurance_covered IS NULL THEN 1 ELSE 0 END) AS insurance_covered_nulls,
    SUM(CASE WHEN patient_responsibility IS NULL THEN 1 ELSE 0 END) AS patient_responsibility_nulls,
    SUM(CASE WHEN payment_status IS NULL THEN 1 ELSE 0 END) AS payment_status_nulls,
    SUM(CASE WHEN due_date IS NULL THEN 1 ELSE 0 END) AS due_date_nulls,
    SUM(CASE WHEN paid_date IS NULL THEN 1 ELSE 0 END) AS paid_date_nulls
FROM Billing;
-- RESULT: 24 null values identified in paid_date column

-- Resolve Billing paid_date null values
UPDATE Billing 
SET paid_date = 'none'
WHERE paid_date IS NULL;

-- 2.3 LabResults Table - Null Value Assessment
SELECT 
    SUM(CASE WHEN lab_id IS NULL THEN 1 ELSE 0 END) AS lab_id_nulls,
    SUM(CASE WHEN patient_id IS NULL THEN 1 ELSE 0 END) AS patient_id_nulls,
    SUM(CASE WHEN staff_id IS NULL THEN 1 ELSE 0 END) AS staff_id_nulls,
    SUM(CASE WHEN test_date IS NULL THEN 1 ELSE 0 END) AS test_date_nulls,
    SUM(CASE WHEN test_result IS NULL THEN 1 ELSE 0 END) AS test_result_nulls,
    SUM(CASE WHEN normal_range IS NULL THEN 1 ELSE 0 END) AS normal_range_nulls,
    SUM(CASE WHEN units IS NULL THEN 1 ELSE 0 END) AS units_nulls,
    SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END) AS status_nulls,
    SUM(CASE WHEN notes IS NULL THEN 1 ELSE 0 END) AS notes_nulls,
    SUM(CASE WHEN test_type IS NULL THEN 1 ELSE 0 END) AS test_type_nulls
FROM LabResults;
-- RESULT: No null values identified

-- 2.4 MedicalRecords Table - Null Value Assessment
SELECT * FROM MedicalRecords
WHERE record_id IS NULL 
   OR patient_id IS NULL 
   OR staff_id IS NULL 
   OR visit_date IS NULL 
   OR diagnosis IS NULL 
   OR treatment IS NULL 
   OR medications_prescribed IS NULL 
   OR blood_pressure IS NULL 
   OR heart_rate IS NULL 
   OR temperature IS NULL 
   OR weight_kg IS NULL 
   OR height_cm IS NULL 
   OR notes IS NULL 
   OR follow_up_required IS NULL;
-- RESULT: 3 rows with null values identified (no action required)

-- 2.5 Patients Table - Null Value Assessment & Resolution
SELECT * FROM Patients
WHERE first_name IS NULL 
   OR last_name IS NULL 
   OR date_of_birth IS NULL 
   OR phone IS NULL
   OR email IS NULL 
   OR address IS NULL 
   OR city IS NULL 
   OR state IS NULL 
   OR zip_code IS NULL 
   OR insurance_provider IS NULL 
   OR insurance_id IS NULL 
   OR registration_date IS NULL 
   OR emergency_contact IS NULL 
   OR emergency_phone IS NULL;
-- RESULT: Null values identified in email, address, phone, and emergency_phone

-- Resolve Patient null values
UPDATE Patients
SET email = 'Unknown',
    phone = 'Unknown',
    address = 'Unknown',
    emergency_phone = 'Unknown'
WHERE email IS NULL 
   OR phone IS NULL 
   OR address IS NULL 
   OR emergency_phone IS NULL;

-- *****************************************************
-- 3. DATA STANDARDIZATION & FORMATTING
-- *****************************************************

-- 3.1 Appointments Table - Notes Standardization
SELECT notes, COUNT(patient_id) AS appointment_count
FROM Appointments
GROUP BY notes;

-- Standardize appointment notes
UPDATE Appointments
SET notes = 'Acne treatment'
WHERE notes = 'Acne';

UPDATE Appointments
SET notes = 'Heart health'
WHERE notes = 'Heart concerns';

-- 3.2 Billing Table - Service Description Standardization
SELECT service_description, COUNT(bill_id) AS service_count
FROM Billing 
GROUP BY service_description;

-- Standardize service descriptions
UPDATE Billing
SET service_description = 'Vaccination'
WHERE service_description = 'Vaccination Administration';

UPDATE Billing 
SET service_description = 'Physical Therapy'
WHERE service_description = 'Physical Therapy Session';

-- 3.3 MedicalRecords Table - Follow-up Requirement Standardization
SELECT follow_up_required FROM MedicalRecords;

-- Standardize follow-up required field
UPDATE MedicalRecords
SET follow_up_required = 'Yes'
WHERE follow_up_required = '1';

UPDATE MedicalRecords
SET follow_up_required = 'No'
WHERE follow_up_required = '0';

-- 3.4 MedicalRecords Table - Treatment Notes Standardization
UPDATE MedicalRecords
SET treatment = 'Patient did not show'
WHERE treatment = 'Patient no-show'
   OR treatment = 'No-show';

UPDATE MedicalRecords
SET notes = 'Missed appointment'
WHERE notes = 'No-show appointment';

-- *****************************************************
-- 4. DATA STRUCTURE VALIDATION
-- *****************************************************

-- Verify table structures and data types
PRAGMA table_info(Appointments);
PRAGMA table_info(MedicalRecords);
-- NOTE: All date fields are stored as TEXT in YYYY-MM-DD format (SQLite constraint)

-- =====================================================
-- DATA QUALITY ASSESSMENT COMPLETE
-- Dataset is now prepared for analytical processing
-- and Power BI dashboard development
-- =====================================================