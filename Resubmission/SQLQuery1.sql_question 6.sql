
-- QUESTION 6



IF COL_LENGTH('dw.factbookings', 'booking_date') IS NULL
BEGIN
    ALTER TABLE dw.factbookings
    ADD booking_date DATE NULL;
END;
GO


UPDATE f
SET
    f.booking_date = d.calendar_date
FROM dw.factbookings AS f
INNER JOIN dw.dimdate AS d
    ON f.booking_date_sk = d.date_sk
WHERE f.booking_date IS NULL;
GO




SELECT
    COUNT(*) AS total_fact_rows,
    COUNT(booking_date) AS populated_booking_dates,
    COUNT(*) - COUNT(booking_date) AS missing_booking_dates
FROM dw.factbookings;
GO




IF NOT EXISTS
(
    SELECT 1
    FROM dw.factbookings
    WHERE booking_date IS NULL
)
BEGIN
    ALTER TABLE dw.factbookings
    ALTER COLUMN booking_date DATE NOT NULL;
END;
GO


-- ============================================================
--- Create partition function
-- ============================================================

IF NOT EXISTS
(
    SELECT 1
    FROM sys.partition_functions
    WHERE name = 'pf_factbookings_bookingdate'
)
BEGIN

    CREATE PARTITION FUNCTION pf_factbookings_bookingdate
    (DATE)
    AS RANGE RIGHT
    FOR VALUES
    (
        '2025-01-01',
        '2026-01-01',
        '2027-01-01'
    );

END;
GO


-- ============================================================
--  Create partition scheme
-- ============================================================

IF NOT EXISTS
(
    SELECT 1
    FROM sys.partition_schemes
    WHERE name = 'ps_factbookings_bookingdate'
)
BEGIN

    CREATE PARTITION SCHEME ps_factbookings_bookingdate
    AS PARTITION pf_factbookings_bookingdate
    ALL TO ([PRIMARY]);

END;
GO


-- ============================================================
-- Check existing primary key
-- ============================================================

SELECT
    i.name AS index_name,
    i.type_desc,
    i.is_primary_key
FROM sys.indexes AS i
WHERE i.object_id = OBJECT_ID('dw.factbookings');
GO


-- ============================================================
-- If PK_factbookings is currently CLUSTERED,
-- convert it to NONCLUSTERED.
--

-- ============================================================

IF EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dw.factbookings')
      AND name = 'PK_factbookings'
      AND type = 1
)
BEGIN

    ALTER TABLE dw.factbookings
    DROP CONSTRAINT PK_factbookings;

    ALTER TABLE dw.factbookings
    ADD CONSTRAINT PK_factbookings
    PRIMARY KEY NONCLUSTERED
    (
        booking_id
    );

END;
GO


-- ============================================================

-- If a previous partitioned clustered index exists,
-- drop it before recreating it.
-- ============================================================

IF EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dw.factbookings')
      AND name = 'CX_factbookings_booking_date'
)
BEGIN

    DROP INDEX CX_factbookings_booking_date
    ON dw.factbookings;

END;
GO


-- ============================================================

-- Create clustered partitioned index
-- ============================================================

CREATE CLUSTERED INDEX CX_factbookings_booking_date
ON dw.factbookings
(
    booking_date,
    booking_id
)
ON ps_factbookings_bookingdate
(
    booking_date
);
GO


-- ============================================================
-- Verify indexes
-- ============================================================

SELECT
    i.name AS index_name,
    i.type_desc,
    i.is_primary_key,
    ds.name AS data_space_name
FROM sys.indexes AS i
INNER JOIN sys.data_spaces AS ds
    ON i.data_space_id = ds.data_space_id
WHERE i.object_id = OBJECT_ID('dw.factbookings')
ORDER BY i.index_id;
GO


-- ============================================================
-- Verify partition distribution
-- ============================================================

SELECT
    p.partition_number,
    p.rows
FROM sys.partitions AS p
WHERE p.object_id = OBJECT_ID('dw.factbookings')
  AND p.index_id = 1
ORDER BY p.partition_number;
GO


-- ============================================================
-- Display partition boundaries
-- ============================================================

SELECT
    pf.name AS partition_function,
    prv.boundary_id,
    CONVERT(DATE, prv.value) AS boundary_date
FROM sys.partition_functions AS pf
INNER JOIN sys.partition_range_values AS prv
    ON pf.function_id = prv.function_id
WHERE pf.name = 'pf_factbookings_bookingdate'
ORDER BY prv.boundary_id;
GO


-- ============================================================
-- Test 2026 partition query
-- ============================================================

SELECT
    COUNT(*) AS total_bookings,
    SUM(fare_amount) AS total_fare
FROM dw.factbookings
WHERE booking_date >= '2026-01-01'
  AND booking_date < '2027-01-01';
GO


-- ============================================================
-- Test passenger query
-- ============================================================

SELECT
    passengers_sk,
    COUNT(*) AS total_bookings,
    SUM(fare_amount) AS total_fare
FROM dw.factbookings
GROUP BY passengers_sk
ORDER BY total_bookings DESC;
GO