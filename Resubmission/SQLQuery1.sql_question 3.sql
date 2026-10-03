--question 3

USE VayuAir;
GO

-- ============================================================
-- QUESTION 3
-- LOAD DIMENSIONS AND FACT
-- ============================================================


-- ============================================================
-- 1. LOAD PASSENGER DIMENSION
-- ============================================================

INSERT INTO dw.dimpassengers
(
    passengers_id,
    passengers_name,
    home_airport_code,
    frequent_flyer_tier,
    signup_date
)
SELECT
    passenger_id,
    passenger_name,
    home_airport_code,
    frequent_flyer_tier,
    signup_date
FROM dbo.bronze_passengers;
GO


-- ============================================================
-- 2. LOAD FLIGHT DIMENSION
-- ============================================================

INSERT INTO dw.dimflight
(
    flight_id,
    flight_number,
    origin_airport_code,
    dest_airport_code,
    aircraft_code,
    flight_date
)
SELECT
    flight_id,
    flight_number,
    origin_airport_code,
    dest_airport_code,
    aircraft_code,
    flight_date
FROM dbo.bronze_flights;
GO


-- ============================================================
-- 3. LOAD AIRPORT DIMENSION
-- ============================================================

INSERT INTO dw.dimairports
(
    airport_code,
    airport_name,
    city,
    country,
    region
)
SELECT DISTINCT
    airport_code,
    airport_name,
    city,
    country,
    region
FROM dbo.bronze_airports;
GO


-- ============================================================
-- 4. LOAD AIRCRAFT DIMENSION
-- ============================================================

INSERT INTO dw.dimaircraft
(
    aircraft_code,
    model,
    manufacturer,
    seat_capacity
)
SELECT DISTINCT
    aircraft_code,
    model,
    manufacturer,
    seat_capacity
FROM dbo.bronze_aircraft;
GO


-- ============================================================
-- 5. LOAD DATE DIMENSION
--
-- IMPORTANT:
-- Load dates from:
--   booking_date
--   travel_date
--   flight_date
-- ============================================================

INSERT INTO dw.dimdate
(
    date_key,
    calendar_date,
    year,
    month,
    day
)
SELECT DISTINCT
    YEAR(d) * 10000
        + MONTH(d) * 100
        + DAY(d) AS date_key,

    d AS calendar_date,

    YEAR(d) AS year,

    MONTH(d) AS month,

    DAY(d) AS day

FROM
(
    SELECT CAST(booking_date AS DATE) AS d
    FROM dbo.bronze_bookings
    WHERE booking_date IS NOT NULL

    UNION

    SELECT CAST(travel_date AS DATE) AS d
    FROM dbo.bronze_bookings
    WHERE travel_date IS NOT NULL

    UNION

    SELECT CAST(flight_date AS DATE) AS d
    FROM dbo.bronze_flights
    WHERE flight_date IS NOT NULL
) AS Dates;
GO


-- ============================================================
-- 6. LOAD FACT TABLE
-- ============================================================

INSERT INTO dw.factbookings
(
    booking_id,

    passengers_sk,

    flight_sk,

    origin_airport_sk,

    dest_airport_sk,

    aircraft_sk,

    booking_date_sk,

    travel_date_sk,

    flight_date_sk,

    fare_class,

    booking_status,

    fare_amount,

    tax_amount,

    miles_earned
)
SELECT
    b.booking_id,

    p.passengers_sk,

    f.flight_sk,

    oa.airport_sk,

    da.airport_sk,

    ac.aircraft_sk,

    bd.date_sk,

    td.date_sk,

    fd.date_sk,

    b.fare_class,

    b.booking_status,

    b.fare_amount,

    b.tax_amount,

    b.miles_earned

FROM dbo.bronze_bookings AS b


-- Passenger
INNER JOIN dw.dimpassengers AS p
    ON b.passenger_id = p.passengers_id


-- Flight
INNER JOIN dw.dimflight AS f
    ON b.flight_id = f.flight_id


-- Origin airport
INNER JOIN dw.dimairports AS oa
    ON f.origin_airport_code = oa.airport_code


-- Destination airport
INNER JOIN dw.dimairports AS da
    ON f.dest_airport_code = da.airport_code


-- Aircraft
INNER JOIN dw.dimaircraft AS ac
    ON f.aircraft_code = ac.aircraft_code


-- Booking date
INNER JOIN dw.dimdate AS bd
    ON CAST(b.booking_date AS DATE) = bd.calendar_date


-- Travel date
INNER JOIN dw.dimdate AS td
    ON CAST(b.travel_date AS DATE) = td.calendar_date


-- Flight date
INNER JOIN dw.dimdate AS fd
    ON CAST(f.flight_date AS DATE) = fd.calendar_date;

GO





