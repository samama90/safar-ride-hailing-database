

USE PROJECT_SAFAR

-- =========================================
-- S1 – Nearest Available Drivers (Lahore)
-- Verified drivers NOT on ongoing trips
-- =========================================


SELECT 
    u.full_name,
    v.type,
    v.model
FROM tbl_Driver d
JOIN tbl_User u ON d.user_id = u.user_id
JOIN tbl_Vehicle v ON d.driver_id = v.driver_id
WHERE d.verified = 1                        
AND u.current_city = 'Islamabad'                
AND d.driver_id NOT IN (                   
    SELECT driver_id
    FROM tbl_Trip
    WHERE trip_status = 'ongoing'

);



-- =========================================
-- S2 – Churn Risk: Inactive Customers (30 Days)
-- Includes customers with NO trips
-- =========================================


SELECT 
      u.full_name    AS customer_name,
      c.customer_id,
      u.email,
      MAX(t.request_time) AS last_trip
FROM tbl_Customer c
JOIN tbl_User u ON c.user_id = u.user_id
LEFT JOIN tbl_Trip t ON c.customer_id = t.customer_id
GROUP BY c.customer_id, u.full_name, u.email        -- ← yeh missing tha
HAVING MAX(t.request_time) < DATEADD(DAY, -30, GETDATE())
    OR MAX(t.request_time) IS NULL
ORDER BY last_trip ASC;


-- =========================================
-- S3 – Monthly Payment Method Distribution
-- % of cash, card, wallet payments
-- =========================================


SELECT YEAR(p.payment_date) AS year,
MONTH(p.payment_date) AS month,
COUNT(*) AS total_trips,

CAST(
SUM(CASE WHEN p.method ='cash' THEN 1 ELSE 0 END ) * 100/count(*)
AS Decimal(5,2)) AS cash_payment,

CAST(
SUM(CASE WHEN p.method ='card' THEN 1 ELSE 0 END )* 100/count(*)
AS Decimal(5,2)) AS card_payment,

CAST(
SUM(CASE WHEN p.method ='wallet' THEN 1 ELSE 0 END )* 100/count(*)
AS Decimal(5,2)) AS wallet_payment

FROM tbl_payment p
JOIN tbl_trip t ON p.trip_id = t.trip_id
WHERE t.trip_status = 'completed'
GROUP BY YEAR(p.payment_date), MONTH(p.payment_date)
ORDER BY Year,month;

-- =========================================
-- S4 – License Expiry + Inactivity Risk
-- Expiring within next 5 years (as per your logic)
-- AND no completed trip in last 60 days
-- =========================================

SELECT 
   u.full_name,
   d.license_expiry,
   MAX(t.end_time) AS last_trip 
FROM tbl_driver d
JOIN tbl_user u ON d.user_id = u.user_id
LEFT JOIN tbl_trip t ON d.driver_id = t.driver_id
AND t.trip_status = 'completed'

WHERE d.license_expiry BETWEEN GETDATE() AND DATEADD(YEAR,5,GETDATE())
GROUP BY   u.full_name,d.license_expiry

HAVING 
MAX(t.end_time) IS NULL
OR MAX(t.end_time)<DATEADD(DAY,-60,GETDATE())

-- =========================================
-- S6 – RIGHT JOIN: All Vehicles with Trip Count
-- Includes vehicles with ZERO trips
-- =========================================

SELECT 
v.model,
v.registration_number,
COUNT(trip_id)
FROM tbl_trip t
RIGHT JOIN tbl_vehicle v ON t.vehicle_id =v.vehicle_id
GROUP BY v.model,v.registration_number
ORDER BY COUNT(trip_id) 

-- =========================================
-- S7 – SELF JOIN: Customers Who Rated Same Driver 5 Stars
-- Avoids duplicate reversed pairs (A-B only)
-- =========================================


SELECT uc1.full_name AS customer1,uc2.full_name AS customer2,ud.full_name AS driver_name,
t1.request_time  AS customer1_trip_date,
t2.request_time  AS customer2_trip_date

FROM tbl_Rating r1
JOIN tbl_Rating r2
ON r1.rated_to = r2.rated_to
AND r1.rated_by < r2.rated_by
AND r1.rating_value = 5
AND r2.rating_value = 5

JOIN tbl_User uc1 ON r1.rated_by = uc1.user_id

JOIN tbl_User uc2 ON r2.rated_by = uc2.user_id

JOIN tbl_User ud ON r1.rated_to = ud.user_id

JOIN tbl_trip t1 ON r1.trip_id = t1.trip_id
JOIN tbl_trip t2 ON r2.trip_id = t2.trip_id

WHERE r1.rated_by IN (SELECT user_id FROM tbl_Customer)
AND   r2.rated_by IN (SELECT user_id FROM tbl_Customer)

AND   r1.rated_to IN (SELECT user_id FROM tbl_Driver)
ORDER BY driver_name;


-- =========================================
-- S8 – Scalar Function
-- Returns total completed trips for a customer
-- =========================================

CREATE FUNCTION fn_CustomerCompletedTrips (@customer_id int)

RETURNS INT

AS
BEGIN 
RETURN
      (SELECT COUNT(trip_id)
      FROM tbl_trip
      WHERE customer_id = @customer_id
      AND trip_status = 'completed'
      )

END;


-- =========================================
-- S9 – Table-Valued Function: Driver Trip Log
-- Returns trips within date range
-- =========================================

CREATE FUNCTION fn_DriverTripLog ( @DriverID INT,@StartDate DATE, @EndDate DATE )
RETURNS TABLE
AS
RETURN
(SELECT 
      t.start_time AS trip_date,
      t.trip_status,
      t.fare_amount,
      u.full_name AS customer_name,
      p.method AS payment_method
 FROM tbl_Trip t
 JOIN tbl_Customer c ON t.customer_id = c.customer_id
 JOIN tbl_User u ON c.user_id = u.user_id
 LEFT JOIN tbl_Payment p ON t.trip_id = p.trip_id
 WHERE t.driver_id = @DriverID
       AND t.start_time BETWEEN @StartDate AND @EndDate
);

-- =========================================
-- Example Execution of Table Function
-- =========================================

SELECT * 
FROM dbo.fn_DriverTripLog(1, '2026-01-01', '2026-03-31');





-- =========================================
-- T1. Driver Cancellation Rate 
--      Show % of cancelled trips for each driver 
--      Only include drivers with at least 5 trips 
-- ========================================= 
 
SELECT d.driver_id, u.full_name AS driver_name, 
   COUNT(t.trip_id) AS total_requests, 
 
   SUM(CASE  
       WHEN t.trip_status = 'cancelled' THEN 1  
       ELSE 0  
       END) AS cancellations, 
 
   CAST( 
       (SUM(CASE  
        WHEN t.trip_status = 'cancelled' THEN 1  
        ELSE 0  
        END) * 100.0) / COUNT(t.trip_id) 
       AS DECIMAL(5,2) 
   ) AS cancellation_percentage 
 
FROM tbl_Driver d 
JOIN tbl_User u ON d.user_id = u.user_id 
JOIN tbl_Trip t ON d.driver_id = t.driver_id 
 
GROUP BY d.driver_id, u.full_name 
HAVING COUNT(t.trip_id) >= 5 
ORDER BY cancellation_percentage DESC; 
 
 
-- ========================================= 
-- T2. Payments Reconciliation 
--      Show all trips and payments (matched or unmatched) 
--      Includes: 
--      1. Trips with no payment 
--      2. Payments with no trip 
-- ========================================= 
 
SELECT t.trip_id, t.fare_amount, p.amount AS payment_amount, 
   p.status AS payment_status 
 
FROM tbl_Trip t FULL JOIN tbl_Payment p  
ON t.trip_id = p.trip_id 
ORDER BY t.trip_id; 
 
 
-- ========================================= 
-- T3. Trip Duration Anomaly Detection 
--      Find trips where: 
--      1. Actual time > 150% of estimated time 
--      2. Fare is greater than overall average fare 
-- ========================================= 
 
SELECT t.trip_id, u.full_name AS driver_name, 
   r.estimated_time, r.actual_time, t.fare_amount 
 
FROM tbl_Trip t 
JOIN tbl_Route r ON t.trip_id = r.trip_id 
JOIN tbl_Driver d ON t.driver_id = d.driver_id 
JOIN tbl_User u ON d.user_id = u.user_id 
 
WHERE  
   r.actual_time > r.estimated_time * 1.5 
   AND t.fare_amount > ( 
       SELECT AVG(fare_amount)  
       FROM tbl_Trip 
   ); 
 
 
 -- ========================================= 
-- T4. Vehicles Expiry Alert (next 30 days) 
--      Show vehicles whose insurance OR registration 
--      is expiring within next 30 days 
--      Grouped by driver with phone number 
-- ========================================= 
 
SELECT d.driver_id, u.full_name AS driver_name, 
   u.phone, v.vehicle_id, v.registration_number, 
   v.insurance_expiry, v.registration_expiry 
 
FROM tbl_Vehicle v 
JOIN tbl_Driver d ON v.driver_id = d.driver_id 
JOIN tbl_User u ON d.user_id = u.user_id 
 
WHERE  
   v.insurance_expiry BETWEEN GETDATE() AND DATEADD(DAY, 30, GETDATE()) 
   OR 
   v.registration_expiry BETWEEN GETDATE() AND DATEADD(DAY, 30, GETDATE()) 
 
ORDER BY d.driver_id; 
 
 
-- ========================================= 
-- T5. Customer Lifetime Value (CLV) Ranking 
--      Calculate net revenue for each customer 
--      Net Revenue = Fare - Commission 
--      Only completed trips 
--      Rank customers using DENSE_RANK() 
--      Show Top 10 customers 
-- ========================================= 
 
SELECT TOP 10 c.customer_id, u.full_name AS customer_name, 
 
   COUNT(t.trip_id) AS total_trips, 
   SUM(t.fare_amount - ISNULL(cm.commission_amount, 0)) AS net_revenue, 
 
   DENSE_RANK() OVER ( 
       ORDER BY SUM(t.fare_amount - ISNULL(cm.commission_amount, 0)) DESC 
   ) AS customer_rank 
 
FROM tbl_Customer c 
JOIN tbl_User u ON c.user_id = u.user_id 
JOIN tbl_Trip t ON c.customer_id = t.customer_id 
LEFT JOIN tbl_Commission cm ON t.trip_id = cm.trip_id 
 
WHERE t.trip_status = 'completed' 
GROUP BY c.customer_id, u.full_name 
ORDER BY net_revenue DESC; 
 
 
-- ========================================= 
-- T6. Show all users with customer details 
--      Include users who are NOT customers 
--      Using RIGHT JOIN 
-- ========================================= 
 
SELECT u.full_name, u.email, c.customer_id 
FROM tbl_Customer c RIGHT JOIN tbl_User u  
ON c.user_id = u.user_id 
ORDER BY u.full_name; 
 
 
-- ========================================= 
-- T7. Find pairs of users living in same city 
--      Conditions: 
--      1. Same city 
--      2. No self-pair (A ≠ A) 
--      3. No duplicate reverse pairs (A-B, not B-A) 
-- ========================================= 
 
SELECT u1.full_name AS user_1, 
   u2.full_name AS user_2, u1.current_city 
 
FROM tbl_User u1 JOIN tbl_User u2  
ON u1.current_city = u2.current_city 
 
WHERE  
   u1.user_id < u2.user_id   -- avoids self-pair and duplicate pairs 
 
ORDER BY u1.current_city, u1.full_name; 
 
 
-- ========================================= 
-- T8. Scalar Function 
--      Total fare of a customer (completed trips only) 
-- ========================================= 
GO 
CREATE FUNCTION dbo.fn_CustomerTotalFare (@CustomerID INT) 
RETURNS DECIMAL(10,2) 
AS 
BEGIN 
   DECLARE @TotalFare DECIMAL(10,2); 
 
   SELECT @TotalFare = SUM(fare_amount) 
   FROM tbl_Trip 
   WHERE customer_id = @CustomerID 
   AND trip_status = 'completed'; 
 
   RETURN ISNULL(@TotalFare, 0); 
END; 
 
-- Call function for a customer 
 
SELECT  
   c.customer_id, u.full_name, 
   dbo.fn_CustomerTotalFare(c.customer_id) AS total_fare 
FROM tbl_Customer c JOIN tbl_User u  
ON c.user_id = u.user_id 
WHERE c.customer_id = 1; 
 
 
-- ========================================= 
-- T9. Table-Valued Function 
--      Top customers by city (completed trips only) 
-- ========================================= 
GO 
CREATE FUNCTION dbo.fn_TopCustomersByCity (@City NVARCHAR(50)) 
RETURNS TABLE 
AS 
RETURN ( 
   SELECT u.full_name AS customer_name, 
   COUNT(t.trip_id) AS total_trips, 
   SUM(t.fare_amount) AS total_spending, 
   MAX(t.request_time) AS last_trip_date 
 
   FROM tbl_User u 
   JOIN tbl_Customer c ON u.user_id = c.user_id 
   JOIN tbl_Trip t ON c.customer_id = t.customer_id 
 
   WHERE u.current_city = @City 
     AND t.trip_status = 'completed' 
 
   GROUP BY u.full_name 
); 
 
-- Call function for specific city (e.g., Lahore) 
 
SELECT * 
FROM dbo.fn_TopCustomersByCity('Lahore'); 
 
 
-- ========================================= 
-- T10. Expired Insurance Report 
--      Show vehicles whose insurance is expired 
--      Using CURSOR + IF condition 
-- ========================================= 
 
CREATE PROCEDURE sp_ExpiredInsuranceReport 
AS 
BEGIN 
 
   DECLARE @reg_number NVARCHAR(20), @expiry_date DATE; 
 
   -- Cursor to fetch vehicle data 
   DECLARE vehicle_cursor CURSOR FOR 
   SELECT registration_number, insurance_expiry 
   FROM tbl_Vehicle; 
 
   OPEN vehicle_cursor; 
 
   FETCH NEXT FROM vehicle_cursor INTO @reg_number, @expiry_date; 
 
   WHILE @@FETCH_STATUS = 0 
   BEGIN 
       IF @expiry_date < GETDATE() 
       BEGIN 
           PRINT 'Vehicle ' + @reg_number +  
                 ' – insurance expired on ' +  
                 CAST(@expiry_date AS NVARCHAR); 
       END 
 
       FETCH NEXT FROM vehicle_cursor INTO @reg_number, @expiry_date; 
   END 
 
   CLOSE vehicle_cursor; 
   DEALLOCATE vehicle_cursor; 
 
END; 
 
-- Call Expired Insurance Report Procedure 
 
EXEC sp_ExpiredInsuranceReport; 
 
 
-- ========================================= 
-- T11. Tiered Commission Update 
--      Update commission based on monthly trips 
--      Using CURSOR + IF ELSE + WHILE 
-- ========================================= 
 
CREATE PROCEDURE sp_ApplyTieredCommission 
   @Year INT, @Month INT 
AS 
BEGIN 
 
   DECLARE @driver_id INT, @trip_count INT; 
 
   -- Cursor for drivers 
   DECLARE driver_cursor CURSOR FOR 
   SELECT driver_id FROM tbl_Driver; 
 
   OPEN driver_cursor; 
 
   FETCH NEXT FROM driver_cursor INTO @driver_id; 
 
   WHILE @@FETCH_STATUS = 0 
   BEGIN 
 
       -- Count completed trips for that driver in given month/year 
       SELECT @trip_count = COUNT(*) 
       FROM tbl_Trip 
       WHERE driver_id = @driver_id 
         AND trip_status = 'completed' 
         AND YEAR(request_time) = @Year 
         AND MONTH(request_time) = @Month; 
 
       -- Apply commission logic 
       IF @trip_count >= 100 
       BEGIN 
           UPDATE tbl_Commission 
           SET rate_percentage = 10, 
               commission_amount = commission_amount * 0.10 
           WHERE trip_id IN ( 
               SELECT trip_id FROM tbl_Trip 
               WHERE driver_id = @driver_id 
           ); 
       END 
 
       ELSE IF @trip_count BETWEEN 50 AND 99 
       BEGIN 
           UPDATE tbl_Commission 
           SET rate_percentage = 12, 
               commission_amount = commission_amount * 0.12 
           WHERE trip_id IN ( 
               SELECT trip_id FROM tbl_Trip 
               WHERE driver_id = @driver_id 
           ); 
       END 
 
       ELSE 
       BEGIN 
           UPDATE tbl_Commission 
           SET rate_percentage = 15, 
               commission_amount = commission_amount * 0.15 
           WHERE trip_id IN ( 
               SELECT trip_id FROM tbl_Trip 
               WHERE driver_id = @driver_id 
           ); 
       END 
 
       FETCH NEXT FROM driver_cursor INTO @driver_id; 
 
   END 
 
   CLOSE driver_cursor; 
   DEALLOCATE driver_cursor; 
 
END; 
 
-- Call Tiered Commission Procedure 
 
EXEC sp_ApplyTieredCommission @Year = 2026, @Month = 3; 
 
 
-------------------------------------------------------


-- ======================================================
-- Tayyab – Additional Business Analytics & Functions
-- ======================================================

-- Y11 – Driver Utilisation Rate
-- For each driver, calculate total minutes spent driving (sum of
-- DATEDIFF(MINUTE, start_time, end_time) for completed trips in last
-- 30 days). Assume a driver is "available" for 8 hours on any day they
-- had at least one trip. Show driver name, total driving minutes, total
-- available minutes, and utilisation percentage. Sort lowest to highest.
-- ------------------------------------------------------
SELECT
    d.driver_id,
    u.full_name AS driver_name,
    ISNULL(SUM(DATEDIFF(MINUTE, t.start_time, t.end_time)), 0) AS total_driving_minutes,
    ISNULL(COUNT(DISTINCT CAST(t.request_time AS DATE)) * 480, 0) AS total_available_minutes,
    ISNULL(CAST(SUM(DATEDIFF(MINUTE, t.start_time, t.end_time)) * 100.0 /
           NULLIF(COUNT(DISTINCT CAST(t.request_time AS DATE)) * 480, 0) AS DECIMAL(5,2)), 0) AS utilisation_pct
FROM tbl_Driver d
JOIN tbl_User u ON d.user_id = u.user_id
LEFT JOIN tbl_Trip t ON d.driver_id = t.driver_id
    AND t.trip_status = 'completed'
    AND t.start_time IS NOT NULL
    AND t.end_time IS NOT NULL
    AND t.request_time BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY d.driver_id, u.full_name
ORDER BY utilisation_pct ASC;


-- Y12 – Top 5 Revenue Routes
-- Identify the 5 most profitable pickup dropoff area pairs. Show pickup
-- area, dropoff area, total revenue, and rank using RANK(). If two
-- routes have the same revenue, they share the same rank.
-- ------------------------------------------------------
SELECT
    lp.address_label AS PickUp,
    ld.address_label AS Dropoff,
    SUM(p.amount) AS TotalRevenue
FROM tbl_Trip t
JOIN tbl_Payment p ON t.trip_id = p.trip_id
JOIN tbl_Location lp ON lp.location_id = t.pickup_location_id
JOIN tbl_Location ld ON ld.location_id = t.dropoff_location_id
GROUP BY lp.address_label, ld.address_label
ORDER BY TotalRevenue DESC;

-- With RANK() – Top 5
SELECT TOP 5
    lp.address_label AS PickUp,
    ld.address_label AS Dropoff,
    SUM(p.amount) AS TotalRevenue,
    RANK() OVER (ORDER BY SUM(p.amount) DESC) AS RouteRank
FROM tbl_Trip t
JOIN tbl_Payment p ON t.trip_id = p.trip_id
JOIN tbl_Location lp ON lp.location_id = t.pickup_location_id
JOIN tbl_Location ld ON ld.location_id = t.dropoff_location_id
GROUP BY lp.address_label, ld.address_label
ORDER BY TotalRevenue DESC;


-- Y15 – INNER JOIN: Trips with Full Details
-- Write a query that joins tbl_Trip, tbl_Customer, tbl_Driver, tbl_User
-- (twice – for customer name and driver name), tbl_Payment, and
-- tbl_Rating. Show trip ID, customer name, driver name, fare, payment
-- method, and rating value.
-- ------------------------------------------------------
SELECT
    t.trip_id,
    Uc.full_name AS Customer_Name,
    Ud.full_name AS Driver_Name,
    t.fare_amount AS Fare,
    R.rating_value
FROM tbl_Trip t
JOIN tbl_Customer c ON t.customer_id = c.customer_id
JOIN tbl_User Uc ON c.user_id = Uc.user_id
JOIN tbl_Payment p ON p.trip_id = t.trip_id
JOIN tbl_Driver d ON d.driver_id = t.driver_id
JOIN tbl_User Ud ON d.user_id = Ud.user_id
JOIN tbl_Rating r ON t.trip_id = r.trip_id;


-- Y16 – LEFT JOIN: All Drivers with Trip Count
-- Show all drivers with the number of completed trips they've done.
-- Include drivers with zero completed trips. Show driver name and trip count.
-- ------------------------------------------------------
SELECT
    Ud.full_name,
    d.total_rides_completed
FROM tbl_Driver d
JOIN tbl_User Ud ON d.user_id = Ud.user_id;

-- (Alternative: actually counting completed trips via LEFT JOIN)
SELECT
    Ud.full_name,
    COUNT(t.trip_id) AS completed_trips
FROM tbl_Driver d
LEFT JOIN tbl_Trip t ON t.driver_id = d.driver_id
JOIN tbl_User Ud ON d.user_id = Ud.user_id
    AND t.trip_status = 'completed'
GROUP BY Ud.full_name;


-- Y17 – Scalar Function: Monthly Revenue
-- Create a function fn_MonthlyRevenue that takes @YearMonth NVARCHAR(7)
-- (format 'YYYY-MM') and returns the total fare revenue for completed
-- trips in that month.
-- ------------------------------------------------------
CREATE FUNCTION fn_MonthlyRevenue (@YearMonth NVARCHAR(7))
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @MonthlyRevenue DECIMAL(10,2);

    SELECT @MonthlyRevenue = SUM(fare_amount)
    FROM tbl_Trip
    WHERE trip_status = 'completed'
      AND FORMAT(request_time, 'yyyy-MM') = @YearMonth;

    RETURN ISNULL(@MonthlyRevenue, 0);
END;

-- Example call:
-- SELECT dbo.fn_MonthlyRevenue('2026-02') AS MonthlyRevenue;


-- Y18 – Scalar Function: Customer Acquisition Cohort
-- Create a function fn_CustomerAcquisition that takes @YearMonth
-- NVARCHAR(7) and returns the number of customers who took their first
-- ever trip in that month.
-- ------------------------------------------------------
CREATE FUNCTION fn_CustomerAcquisition (@YearMonth NVARCHAR(7))
RETURNS INT
AS
BEGIN
    DECLARE @Count INT;

    SELECT @Count = COUNT(*)
    FROM (
        SELECT MIN(request_time) AS first_trip
        FROM tbl_Trip t
        JOIN tbl_Customer c ON c.customer_id = t.customer_id
        JOIN tbl_User uc ON uc.user_id = c.user_id
        GROUP BY c.customer_id
    ) AS FirstTrips
    WHERE FORMAT(FirstTrips.first_trip, 'yyyy-MM') = @YearMonth;

    RETURN @Count;
END;

-- Example call:
-- SELECT dbo.fn_CustomerAcquisition('2026-01');


-- Y19 – Table Valued Function: Trips with Payments Between Dates
-- Create a function fn_TripsPaymentsBetween that takes @StartDate DATE,
-- @EndDate DATE and returns a table with all trips in that range along
-- with their payment details (amount, method, status). Include trips
-- with no payment.
-- ------------------------------------------------------
CREATE FUNCTION fn_TripsPaymentsBetween (@StartDate DATE, @EndDate DATE)
RETURNS TABLE
AS
RETURN
(
    SELECT
        t.trip_id,
        t.request_time,
        t.fare_amount,
        p.amount AS Payment_Amount,
        p.method,
        p.status
    FROM tbl_Trip t
    LEFT JOIN tbl_Payment p ON t.trip_id = p.trip_id
    WHERE t.request_time BETWEEN @StartDate AND @EndDate
);

-- Example call:
-- SELECT * FROM dbo.fn_TripsPaymentsBetween('2026-01-01', '2026-03-31');