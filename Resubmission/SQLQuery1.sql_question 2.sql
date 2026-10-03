USE VayuAir;
GO

-- ============================================================
-- QUESTION 2
-- CREATE STAR SCHEMA
-- ============================================================

-- Drop tables first
DROP TABLE IF EXISTS dw.factbookings;
DROP TABLE IF EXISTS dw.dimpassengers;
DROP TABLE IF EXISTS dw.dimairports;
DROP TABLE IF EXISTS dw.dimaircraft;
DROP TABLE IF EXISTS dw.dimflight;
DROP TABLE IF EXISTS dw.dimdate;

-- Drop schema
DROP SCHEMA IF EXISTS dw;
GO


-- Create schema
CREATE SCHEMA dw;
GO


-- ============================================================
-- DATE DIMENSION
-- ============================================================

CREATE TABLE dw.dimdate
(
    date_sk INT IDENTITY(1,1) PRIMARY KEY,

    date_key INT NOT NULL,

    calendar_date DATE NOT NULL,

    year INT,
    month INT,
    day INT,

    CONSTRAINT UQ_dimdate_date
        UNIQUE (calendar_date)
);
GO


-- ============================================================
-- FLIGHT DIMENSION
-- ============================================================

CREATE TABLE dw.dimflight
(
    flight_sk INT IDENTITY(1,1) PRIMARY KEY,

    flight_id INT NOT NULL,

    flight_number NVARCHAR(50),

    origin_airport_code NVARCHAR(50),

    dest_airport_code NVARCHAR(50),

    aircraft_code NVARCHAR(50),

    flight_date DATE
);
GO


-- ============================================================
-- AIRCRAFT DIMENSION
-- ============================================================

CREATE TABLE dw.dimaircraft
(
    aircraft_sk INT IDENTITY(1,1) PRIMARY KEY,

    aircraft_code NVARCHAR(50),

    model NVARCHAR(100),

    manufacturer NVARCHAR(100),

    seat_capacity INT
);
GO


-- ============================================================
-- AIRPORT DIMENSION
-- ============================================================

CREATE TABLE dw.dimairports
(
    airport_sk INT IDENTITY(1,1) PRIMARY KEY,

    airport_code NVARCHAR(50) NOT NULL,

    airport_name NVARCHAR(100),

    city NVARCHAR(100),

    country NVARCHAR(100),

    region NVARCHAR(100)
);
GO


-- ============================================================
-- PASSENGER DIMENSION
-- ============================================================

CREATE TABLE dw.dimpassengers
(
    passengers_sk INT IDENTITY(1,1) PRIMARY KEY,

    passengers_id INT NOT NULL,

    passengers_name NVARCHAR(100),

    home_airport_code NVARCHAR(50),

    frequent_flyer_tier NVARCHAR(50),

    signup_date DATE
);
GO


-- ============================================================
-- BOOKING FACT
-- Grain:
-- One row = one booking / ticket on one flight
-- ============================================================

CREATE TABLE dw.factbookings
(
    booking_id INT NOT NULL,

    passengers_sk INT NOT NULL,

    flight_sk INT NOT NULL,

    origin_airport_sk INT NOT NULL,

    dest_airport_sk INT NOT NULL,

    aircraft_sk INT NOT NULL,

    booking_date_sk INT NOT NULL,

    travel_date_sk INT NOT NULL,

    flight_date_sk INT NOT NULL,

    -- Dimension attributes identified in Q1
    fare_class NVARCHAR(50),

    booking_status NVARCHAR(50),

    -- Measures
    fare_amount DECIMAL(18,2),

    tax_amount DECIMAL(18,2),

    miles_earned INT,


    CONSTRAINT PK_factbookings
        PRIMARY KEY (booking_id),


    CONSTRAINT FK_factbookings_passenger
        FOREIGN KEY (passengers_sk)
        REFERENCES dw.dimpassengers(passengers_sk),


    CONSTRAINT FK_factbookings_flight
        FOREIGN KEY (flight_sk)
        REFERENCES dw.dimflight(flight_sk),


    CONSTRAINT FK_factbookings_origin
        FOREIGN KEY (origin_airport_sk)
        REFERENCES dw.dimairports(airport_sk),


    CONSTRAINT FK_factbookings_destination
        FOREIGN KEY (dest_airport_sk)
        REFERENCES dw.dimairports(airport_sk),


    CONSTRAINT FK_factbookings_aircraft
        FOREIGN KEY (aircraft_sk)
        REFERENCES dw.dimaircraft(aircraft_sk),


    CONSTRAINT FK_factbookings_bookingdate
        FOREIGN KEY (booking_date_sk)
        REFERENCES dw.dimdate(date_sk),


    CONSTRAINT FK_factbookings_traveldate
        FOREIGN KEY (travel_date_sk)
        REFERENCES dw.dimdate(date_sk),


    CONSTRAINT FK_factbookings_flightdate
        FOREIGN KEY (flight_date_sk)
        REFERENCES dw.dimdate(date_sk)
);
GO