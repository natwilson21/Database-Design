-- Identifying Adverse Drug Events (ADEs) with Stored Programs
-- CS 3200 / CS5200: Databases

-- We've already setup the ade database by running ade_setup.sql
-- First, make ade the active database.
USE ade;

-- A stored procedure to process and validate prescriptions
-- Four things we need to check
-- a) Is patient a child and is medication suitable for children?
-- b) Is patient pregnant and is medication suitable for pregnant women?
-- c) Are there any adverse drug reactions

DROP PROCEDURE IF EXISTS prescribe;
delimiter //
CREATE PROCEDURE prescribe
(
    IN patient_name_param VARCHAR(255),
    IN doctor_name_param VARCHAR(255),
    IN medication_name_param VARCHAR(255),
    IN ppd_param INT -- pills per day prescribed
)
BEGIN
	-- variable declarations
    DECLARE patient_id_var INT;
    DECLARE age_var FLOAT;
    DECLARE is_pregnant_var BOOLEAN;
    DECLARE weight_var INT;
    DECLARE doctor_id_var INT;
    DECLARE medication_id_var INT;
    DECLARE take_under_12_var BOOLEAN;
    DECLARE take_if_pregnant_var BOOLEAN;
    DECLARE mg_per_pill_var DOUBLE;
    DECLARE max_mg_per_10kg_var DOUBLE;
    DECLARE message VARCHAR(255); -- The error message
    DECLARE ddi_medication VARCHAR(255); -- The name of a medication involved in a drug-drug interaction

    -- select relevant values into variables
    -- check age of patient
	SELECT 
		IF((SELECT YEAR(CURRENT_TIMESTAMP()) - YEAR(p.dob)) < 12 AND m.take_under_12 = 0, 0, 1) AS 'Suitable_For_Age'
	INTO take_under_12_var
    FROM patient p, medication m
	WHERE p.patient_name = patient_name_param AND m.medication_name = medication_name_param;
    IF take_under_12_var = 0 THEN
		SIGNAL SQLSTATE 'HY000'
			SET MESSAGE_TEXT = "Patient is too young for this medicine.";
	END IF;
    
    -- check if medication ok for pregnant women
	SELECT
		IF((p.is_pregnant = 1 AND m.take_if_pregnant = 1) OR p.is_pregnant = 0, 1, 0) AS "Suitable_For_Pregnant_Women"
	INTO take_if_pregnant_var
    FROM patient p, medication m
	WHERE p.patient_name = patient_name_param AND m.medication_name = medication_name_param;
    IF take_if_pregnant_var = 0 THEN
		SIGNAL SQLSTATE 'HY000'
			SET MESSAGE_TEXT = "Medicine is not suitable for pregnant women.";
	END IF;
    
    -- Check for reactions involving medications already prescribed to patient
	SELECT 
	p.medication_id AS 'Prescribed Medicine_id',
    p.patient_id AS 'Patient_ID',
	i.medication_1 AS 'Med_1',
    i.medication_2 AS 'Med_2', 
    m.medication_id AS 'Medicine_ID', 
    IF(m.medication_id = i.medication_2 AND p.medication_id = i.medication_1, 'Reaction', 'No Reaction') AS 'Reactions'
INTO medication_id_var, patient_id_var, medication_id_var, medication_id_var, medication_id_var, ddi_medication
FROM interaction i
LEFT JOIN medication m ON (m.medication_id = i.medication_2)
LEFT JOIN prescription p ON (p.medication_id = i.medication_1)
LEFT JOIN patient pat ON (pat.patient_id = p.patient_id)
WHERE pat.patient_name = patient_name_param AND m.medication_name = medication_name_param;
IF ddi_medication = 'Reaction' THEN
		SIGNAL SQLSTATE 'HY000'
			SET MESSAGE_TEXT = "Medicine will cause reactions with existing prescibed medicine.";
END IF;

    -- No exceptions thrown, so insert the prescription record
INSERT INTO prescription (medication_id, patient_id, doctor_id, prescription_dt, ppd) 
VALUES (
	(SELECT m.medication_id FROM medication m WHERE m.medication_name = medication_name_param), 
	(SELECT p.patient_id FROM patient p WHERE p.patient_name = patient_name_param), 
    (SELECT doc.doctor_id FROM doctor doc WHERE doc.doctor_name = doctor_name_param), 
    CURRENT_TIMESTAMP(),
    ppd_param);
END //
delimiter ;

-- Trigger
DROP TRIGGER IF EXISTS patient_after_update_pregnant;
DELIMITER //
CREATE TRIGGER patient_after_update_pregnant
	AFTER UPDATE ON patient
	FOR EACH ROW
BEGIN
    -- Patient became pregnant
    -- Add pre-natal recommenation
    -- Delete any prescriptions that shouldn't be taken if pregnant
	IF(new.is_pregnant = TRUE) THEN 
		INSERT INTO recommendation (patient_id, message)
        VALUES (new.patient_id, "Take pre-natal vitamins");
	END IF;
    
    IF(new.is_pregnant = TRUE) THEN
		DELETE FROM prescription WHERE (old.patient_id = prescription.patient_id) AND (prescription.medication_id = 2 OR 4 OR 9);
    END IF;
    
    -- Patient is no longer pregnant
    -- Remove pre-natal recommendation
	IF(new.is_pregnant = FALSE) THEN 
		DELETE FROM recommendation WHERE (old.patient_id = recommendation.patient_id) AND (message = "Take pre-natal vitamins");
	END IF;
END //
DELIMITER ;

-- --------------------------                  TEST CASES                     -----------------------
TRUNCATE prescription;

-- These prescriptions should succeed
CALL prescribe('Jones', 'Dr.Marcus', 'Happyza', 2);
CALL prescribe('Johnson', 'Dr.Marcus', 'Forgeta', 1);
CALL prescribe('Williams', 'Dr.Marcus', 'Happyza', 1);
CALL prescribe('Phillips', 'Dr.McCoy', 'Forgeta', 1);

-- These prescriptions should fail
-- Pregnancy violation
CALL prescribe('Jones', 'Dr.Marcus', 'Forgeta', 2);

-- Age restriction
CALL prescribe('BillyTheKid', 'Dr.Marcus', 'Muscula', 1);

-- Drug interaction
CALL prescribe('Williams', 'Dr.Marcus', 'Sadza', 1);

-- Testing trigger
-- Phillips (patient_id=4) becomes pregnant
-- Verify that a recommendation for pre-natal vitamins is added
-- and that her prescription for
SELECT * FROM patient;
UPDATE patient 
SET is_pregnant = TRUE 
WHERE patient_id = 4;

SELECT * FROM recommendation;
SELECT * FROM prescription;
SELECT * FROM medication;

-- Phillips (patient_id=4) is no longer pregnant
-- Verify that the prenatal vitamin recommendation is gone
-- Her old prescription does not need to be added back
UPDATE patient
SET is_pregnant = FALSE
WHERE patient_id = 4;

SELECT * FROM recommendation;
