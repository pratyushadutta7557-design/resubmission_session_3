-- ============================================================
-- QUESTION 5
-- SCD TYPE 2 - PASSENGER DIMENSION
-- ============================================================

USE VayuAir;
GO


/* ============================================================
   STEP 0: Add SCD Type 2 columns only if they don't exist
   ============================================================ */

IF COL_LENGTH('dw.dimpassengers', 'is_current') IS NULL
BEGIN
    ALTER TABLE dw.dimpassengers
    ADD is_current BIT NULL;
END;
GO


IF COL_LENGTH('dw.dimpassengers', 'effective_from') IS NULL
BEGIN
    ALTER TABLE dw.dimpassengers
    ADD effective_from DATE NULL;
END;
GO


IF COL_LENGTH('dw.dimpassengers', 'effective_to') IS NULL
BEGIN
    ALTER TABLE dw.dimpassengers
    ADD effective_to DATE NULL;
END;
GO


/* ============================================================
   STEP 1: Initialize existing passenger records
   ============================================================ */

UPDATE dw.dimpassengers
SET
    effective_from = signup_date,
    effective_to = NULL,
    is_current = 1
WHERE effective_from IS NULL;
GO


/* ============================================================
   STEP 2: Remove temporary table if it already exists
   ============================================================ */

DROP TABLE IF EXISTS #ExpiredPassengers;
GO


/* ============================================================
   STEP 3: Create temporary audit table
   ============================================================ */

CREATE TABLE #ExpiredPassengers
(
    passengers_id INT,
    action_taken VARCHAR(10)
);
GO


/* ============================================================
   STEP 4: PASS 1 - MERGE
   ============================================================ */

MERGE dw.dimpassengers AS tgt

USING dbo.stg_passenger_updates AS src

    /* Match using stable business key */
    ON tgt.passengers_id = src.passenger_id
   AND tgt.is_current = 1


/* ============================================================
   CASE 1:
   Existing passenger whose tier or airport changed
   ============================================================ */

WHEN MATCHED
     AND
     (
         ISNULL(tgt.frequent_flyer_tier, '')
             <> ISNULL(src.frequent_flyer_tier, '')

         OR

         ISNULL(tgt.home_airport_code, '')
             <> ISNULL(src.home_airport_code, '')
     )

THEN
    UPDATE SET

        tgt.is_current = 0,

        tgt.effective_to = CAST(GETDATE() AS DATE)


/* ============================================================
   CASE 2:
   Brand-new passenger
   ============================================================ */

WHEN NOT MATCHED BY TARGET

THEN
    INSERT
    (
        passengers_id,
        passengers_name,
        home_airport_code,
        frequent_flyer_tier,
        signup_date,
        effective_from,
        effective_to,
        is_current
    )

    VALUES
    (
        src.passenger_id,

        src.passenger_name,

        src.home_airport_code,

        src.frequent_flyer_tier,

        -- Staging table does not contain signup_date
        CAST(GETDATE() AS DATE),

        -- Effective from today
        CAST(GETDATE() AS DATE),

        -- Current record has no end date
        NULL,

        -- Current record
        1
    )


/* ============================================================
   Capture MERGE action
   ============================================================ */

OUTPUT
    src.passenger_id,
    $action

INTO #ExpiredPassengers
(
    passengers_id,
    action_taken
);

GO


/* ============================================================
   STEP 5: Check what happened in PASS 1
   ============================================================ */

SELECT
    passengers_id,
    action_taken
FROM #ExpiredPassengers;
GO


/* ============================================================
   STEP 6: PASS 2
   Insert NEW CURRENT version for expired passengers
   ============================================================ */

INSERT INTO dw.dimpassengers
(
    passengers_id,

    passengers_name,

    home_airport_code,

    frequent_flyer_tier,

    signup_date,

    effective_from,

    effective_to,

    is_current
)

SELECT

    src.passenger_id,

    src.passenger_name,

    src.home_airport_code,

    src.frequent_flyer_tier,

    /* Keep original signup date */
    old.signup_date,

    /* New version starts today */
    CAST(GETDATE() AS DATE),

    /* Current version has no end date */
    NULL,

    /* Mark as current */
    1

FROM dbo.stg_passenger_updates AS src


INNER JOIN #ExpiredPassengers AS e

    ON src.passenger_id = e.passengers_id


INNER JOIN dw.dimpassengers AS old

    ON old.passengers_id = src.passenger_id

   AND old.is_current = 0

   AND old.effective_to = CAST(GETDATE() AS DATE)


WHERE e.action_taken = 'UPDATE';

GO


/* ============================================================
   STEP 7: Final SCD Type 2 validation
   ============================================================ */

SELECT

    passengers_sk,

    passengers_id,

    passengers_name,

    home_airport_code,

    frequent_flyer_tier,

    signup_date,

    is_current,

    effective_from,

    effective_to

FROM dw.dimpassengers

ORDER BY
    passengers_id,
    passengers_sk;

GO