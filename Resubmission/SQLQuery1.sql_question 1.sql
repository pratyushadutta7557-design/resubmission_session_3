 CREATE DATABASE VayuAir;
 use VayuAir

-- question 1

-- Grain: One row represents one booking (one ticket) on one flight.

-- Dimension keys:
booking_id
passenger_id
flight_id
booking_date
travel_date
fare_class
booking_status
flight_number
origin_airport_code
dest_airport_code
aircraft_code
flight_date

-- Measures:
fare_amount
tax_amount
miles_earned

-- fare_amount, tax_amount, and miles_earned are additive measures because
-- they can be summed across bookings. A percentage such as discount_percentage
-- would be non-additive because percentages should not be summed.





