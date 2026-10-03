

--question 4

-- ============================================================
-- QUESTION 4
-- Geography Snowflake Dimensions
-- ============================================================


-- ============================================================
-- CREATE COUNTRY DIMENSION
-- ============================================================

CREATE TABLE dw.dimcountry
(
    country_sk INT IDENTITY(1,1) PRIMARY KEY,

    country_name NVARCHAR(100) NOT NULL,

    region NVARCHAR(100)
);
GO


-- ============================================================
-- CREATE CITY DIMENSION
-- ============================================================

CREATE TABLE dw.dimcity
(
    city_sk INT IDENTITY(1,1) PRIMARY KEY,

    city_name NVARCHAR(100) NOT NULL,

    country_sk INT NOT NULL,

    CONSTRAINT FK_DimCity_Country
        FOREIGN KEY (country_sk)
        REFERENCES dw.dimcountry(country_sk)
);
GO


-- ============================================================
-- CREATE AIRPORT DIMENSION
-- ============================================================

CREATE TABLE dw.dimairport
(
    airport_sk INT IDENTITY(1,1) PRIMARY KEY,

    airport_code NVARCHAR(50) NOT NULL,

    airport_name NVARCHAR(100) NOT NULL,

    city_sk INT NOT NULL,

    CONSTRAINT FK_DimAirport_City
        FOREIGN KEY (city_sk)
        REFERENCES dw.dimcity(city_sk)
);
GO


-- ============================================================
-- LOAD COUNTRY
-- DISTINCT prevents duplicate countries
-- ============================================================

INSERT INTO dw.dimcountry
(
    country_name,
    region
)
SELECT DISTINCT
    country,
    region
FROM dbo.bronze_airports
WHERE country IS NOT NULL;
GO


-- ============================================================
-- LOAD CITY
-- DISTINCT prevents duplicate cities
-- ============================================================

INSERT INTO dw.dimcity
(
    city_name,
    country_sk
)
SELECT DISTINCT
    b.city,
    c.country_sk
FROM dbo.bronze_airports AS b

INNER JOIN dw.dimcountry AS c
    ON c.country_name = b.country

WHERE b.city IS NOT NULL
  AND b.country IS NOT NULL;
GO


-- ============================================================
-- LOAD AIRPORT
-- DISTINCT prevents duplicate airports
-- ============================================================

INSERT INTO dw.dimairport
(
    airport_code,
    airport_name,
    city_sk
)
SELECT DISTINCT
    b.airport_code,
    b.airport_name,
    c.city_sk
FROM dbo.bronze_airports AS b

INNER JOIN dw.dimcity AS c
    ON c.city_name = b.city

INNER JOIN dw.dimcountry AS co
    ON co.country_sk = c.country_sk
    AND co.country_name = b.country

WHERE b.airport_code IS NOT NULL
  AND b.airport_name IS NOT NULL
  AND b.city IS NOT NULL;
GO


-- ============================================================
-- VALIDATION
-- ============================================================

SELECT *
FROM dw.dimcountry;

SELECT *
FROM dw.dimcity;

SELECT *
FROM dw.dimairport;