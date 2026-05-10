USE PROJECT_SAFAR

-- ========================================= 
-- Increase fare by 10% for trips between Jan 1 and Mar 1, 2026 
-- ========================================= 
 
UPDATE tbl_Trip  
SET fare_amount = fare_amount * 1.10 
WHERE start_time BETWEEN '2026-01-01' AND '2026-03-01'; 
 
-- ========================================= 
-- Update payment mode to 'wallet' for Karachi customers 
-- Only customers currently using 'cash' or 'card' 
-- ========================================= 
 
  UPDATE tbl_Customer 
  SET default_payment_mode ='wallet' 
  WHERE  default_payment_mode IN('cash','card') 
  AND user_id IN ( 
                  SELECT user_id  
                  FROM tbl_User 
                  WHERE current_city = 'Karachi') 
 
 
-- ========================================= 
-- Count total trips per customer 
-- ========================================= 
 
   SELECT c.customer_id, 
   u.full_name, 
   COUNT(t.trip_id) AS completed_trip 
           FROM tbl_Customer c 
           JOIN tbl_User u ON c.user_id = u.user_id 
           JOIN tbl_Trip t ON c.customer_id = t.customer_id 
           GROUP BY c.customer_id ,u.full_name 
           ORDER BY completed_trip DESC 
 
 
-- ========================================= 
-- Show drivers with more than 1 completed trip 
-- Using GROUP BY + HAVING 
-- ========================================= 
 
   SELECT d.driver_id, 
   u.full_name, 
   COUNT(t.trip_id) AS completed_trip 
           FROM tbl_Driver d 
           JOIN tbl_User u ON d.user_id = u.user_id 
           JOIN tbl_Trip t ON d.driver_id= t.driver_id 
           WHERE t.trip_status = 'completed' 
           GROUP BY d.driver_id ,u.full_name 
           HAVING COUNT(t.trip_id)>1 
           ORDER BY completed_trip DESC 
 
 
-- ========================================= 
-- Show trips of customers who live in Karachi 
-- Using subquery with IN 
-- ========================================= 
 
SELECT *FROM tbl_Trip   
WHERE customer_id IN(  
             SELECT customer_id  
             FROM tbl_Customer  
             WHERE user_id IN(  
                       SELECT user_id  
                       FROM tbl_User  
                       WHERE current_city = 'Karachi')); 
 
---Another method  
 
SELECT *FROM tbl_Trip  
WHERE customer_id IN( 
         SELECT customer_id 
         FROM tbl_Customer c 
         INNER JOIN tbl_User u ON c.user_id = u.user_id 
         WHERE current_city = 'Karachi' 
); 
 
-- ========================================= 
-- Show vehicles NOT used in any trip 
-- ========================================= 
 
SELECT*  
FROM tbl_Vehicle 
WHERE vehicle_id NOT IN( 
      SELECT vehicle_id 
      FROM tbl_Trip 
); 
 
 
-- ========================================= 
-- Calculate total fare from completed trips 
-- ========================================= 
 
 
SELECT SUM(fare_amount) AS Total_Fare 
FROM tbl_Trip 
WHERE trip_status = 'completed' 
 
 
-- ========================================= 
-- Find average rating for a specific driver (driver_id = 1) 
-- ========================================= 
 
SELECT AVG(r.rating_value) AS average_rating 
FROM tbl_Rating r 
INNER JOIN tbl_Trip t ON r.trip_id = t.trip_id 
WHERE t.driver_id = 1; 
 
 
 
-- ========================================= 
-- Count trips per vehicle (including unused vehicles) 
-- ========================================= 
 
SELECT  
v.vehicle_id, 
v.manufacturer, 
v.model, 
v.registration_number, 
COUNT(t.trip_id) AS total_trip 
FROM tbl_Vehicle v 
LEFT JOIN tbl_Trip t ON v.vehicle_id = t.vehicle_id  --USING LEFT JOIN FOR ASLO SHOWING WHO NOT USE IN TRIP 
GROUP BY v.vehicle_id, v.manufacturer, v.model, v.registration_number 
ORDER BY total_trip DESC 
 
 
-- ========================================= 
-- Find minimum and maximum fare 
-- ======================================== 
 
SELECT  
    MIN(fare_amount) AS minimum_fare, 
    MAX(fare_amount) AS maximum_fare 
FROM tbl_Trip; 
 
-- ========================================= 
-- Show all vehicles with driver details 
-- Includes vehicles with NO driver assigned 
-- ========================================= 
 
SELECT v.vehicle_id, 
v.model, 
d.driver_id, 
u.full_name 
 
FROM tbl_Vehicle v 
LEFT JOIN tbl_Driver d ON v.driver_id = d.driver_id 
LEFT JOIN tbl_User u ON d.user_id = u.user_id 
ORDER BY v.vehicle_id asc;




 
-- ========================================= 
-- Change email of user 'Ali Raza' 
-- ========================================= 
 
UPDATE tbl_User 
SET email = 'ali.newemail@gmail.com' 
WHERE full_name = 'Ali Raza'; 
 
 
 
-- ========================================= 
-- Mark all users in Lahore as inactive 
-- ========================================= 
 
UPDATE tbl_User 
SET is_active = 0 
WHERE current_city = 'Lahore'; 
 
 
 
-- ========================================= 
-- Hard delete a user (user_id = 8) 
-- Note: May fail due to foreign key constraints 
-- ========================================= 
 
-- Delete from child table first 
DELETE FROM tbl_Customer 
WHERE user_id = 8; 
 
-- Now delete from parent table 
DELETE FROM tbl_User 
WHERE user_id = 8; 
 
 
 
 
-- ========================================= 
-- Soft delete (deactivate) user 'Hira Butt' 
-- ========================================= 
 
UPDATE tbl_User 
SET is_active = 0 
WHERE full_name = 'Hira Butt'; 
 
 
 
-- ========================================= 
-- Show all active users 
-- ========================================= 
 
SELECT *  
FROM tbl_User 
WHERE is_active = 1; 
 
 
 
-- ========================================= 
-- Show all inactive users 
-- ========================================= 
 
SELECT *  
FROM tbl_User 
WHERE is_active = 0; 
 
 
 
-- ========================================= 
-- Show all cancelled trips 
-- ========================================= 
 
SELECT *  
FROM tbl_Trip 
WHERE trip_status = 'cancelled'; 
 
 
 
-- ========================================= 
-- Show trips with status 'completed' or 'cancelled' 
-- ========================================= 
 
SELECT *  
FROM tbl_Trip 
WHERE trip_status IN ('completed', 'cancelled'); 
 
 
 
-- ========================================= 
-- Show payments made in February 2026 
-- ========================================= 
 
SELECT *  
FROM tbl_Payment 
WHERE payment_date BETWEEN '2026-02-01' AND '2026-02-28'; 
 
 
 
-- ========================================= 
-- Vehicles of type 'car' with seating > 3 
-- ========================================= 
 
SELECT * 
FROM tbl_Vehicle 
WHERE type = 'car' AND seating_capacity > 3; 
 
 
-- ========================================= 
-- Users living in Lahore OR Islamabad 
-- ========================================= 
 
SELECT * 
FROM tbl_User 
WHERE current_city = 'Lahore' OR current_city = 'Islamabad'; 
 
 
 
-- ========================================= 
-- Show trips ordered by highest fare 
-- ========================================= 
 
SELECT * 
FROM tbl_Trip 
ORDER BY fare_amount DESC; 
 
 
 
-- ========================================= 
-- Find users whose name starts with 'A' 
-- ========================================= 
 
SELECT * 
FROM tbl_User 
WHERE full_name LIKE 'A%'; 
 
 
 
-- ========================================= 
-- Find locations where city contains 'aba' 
-- ========================================= 
 
SELECT * 
FROM tbl_Location 
WHERE city LIKE '%aba%'; 
 
 
 
-- ========================================= 
-- Show trips with customer and driver names 
-- ========================================= 
 
SELECT  
    t.trip_id, 
    cu.full_name AS customer_name, 
    du.full_name AS driver_name, 
    t.trip_status, 
    t.fare_amount 
FROM tbl_Trip t 
INNER JOIN tbl_Customer c ON t.customer_id = c.customer_id 
INNER JOIN tbl_User cu ON c.user_id = cu.user_id 
INNER JOIN tbl_Driver d ON t.driver_id = d.driver_id 
INNER JOIN tbl_User du ON d.user_id = du.user_id; 
 
 
 
-- ========================================= 
-- Show all drivers with their vehicles 
-- Includes drivers with no vehicles 
-- ========================================= 
 
SELECT  
    d.driver_id, 
    u.full_name, 
    v.vehicle_id, 
    v.model 
FROM tbl_Driver d 
LEFT JOIN tbl_User u ON d.user_id = u.user_id 
LEFT JOIN tbl_Vehicle v ON d.driver_id = v.driver_id; 
 
 
 
-----------------------------------------------



--    ALTER TABLE demo (test table)
--    Create a test table called tbl_Test.
--    Add a VARCHAR column for remarks, then change its length.
--    Add a constraint that ensures a column value is positive.
--    Drop that constraint.
--    Rename a column.
--    Drop a column.
--    Truncate the table, then drop it.
-- ------------------------------------------------------

CREATE TABLE tbl_Test (
    user_id   INT PRIMARY KEY,
    full_name NVARCHAR(100) NOT NULL,
    email     NVARCHAR(100) UNIQUE NOT NULL,
    AGE       INT
);

ALTER TABLE tbl_Test ADD remarks VARCHAR(10);
ALTER TABLE tbl_Test ALTER COLUMN remarks VARCHAR(40);
ALTER TABLE tbl_Test ADD CONSTRAINT chk_Postive CHECK (AGE > 0);
ALTER TABLE tbl_Test DROP CONSTRAINT IF EXISTS chk_Postive;
EXEC sp_rename 'tbl_Test.AGE', 'User_age', 'COLUMN';
ALTER TABLE tbl_Test DROP COLUMN User_age;
TRUNCATE TABLE tbl_Test;
DROP TABLE tbl_Test;

SELECT * FROM tbl_Test;

--    UPDATE – using GROUP BY / HAVING
--    For drivers who have completed more than 3 trips, increase
--    their total_rides_completed by 1.
-- ------------------------------------------------------

UPDATE tbl_Driver
SET total_rides_completed = total_rides_completed + 1
WHERE driver_id IN (
    SELECT driver_id
    FROM tbl_Trip
    WHERE trip_status = 'completed'
    GROUP BY driver_id
    HAVING COUNT(*) >= 3
);


--    Subquery with ANY
--    Show trips where the fare is greater than ANY completed trip
--    fare of driver ID 1.
-- ------------------------------------------------------
SELECT trip_id, fare_amount
FROM tbl_Trip
WHERE fare_amount > ANY (
    SELECT fare_amount
    FROM tbl_Trip
    WHERE trip_status = 'completed' AND driver_id = 1
);


--    Subquery with ALL
--    Show trips where the fare is greater than ALL trips made by
--    customer ID 2.
-- ------------------------------------------------------
SELECT trip_id
FROM tbl_Trip
WHERE fare_amount > ALL (
    SELECT fare_amount
    FROM tbl_Trip
    WHERE customer_id = 2 AND trip_status = 'completed'
);


--    Subquery with EXISTS
--    Show customers who have given a rating of 5.
-- ------------------------------------------------------
SELECT U.user_id, U.full_name
FROM tbl_User U
JOIN tbl_Customer C ON U.user_id = C.user_id
WHERE EXISTS (
    SELECT 1
    FROM tbl_Rating
    WHERE tbl_Rating.rated_by = U.user_id AND rating_value = 5
);


--    Subquery with NOT EXISTS
--    List drivers who have never received a rating.
-- ------------------------------------------------------
SELECT U.user_id, U.full_name
FROM tbl_User U
JOIN tbl_Driver D ON U.user_id = D.user_id
WHERE NOT EXISTS (
    SELECT 1
    FROM tbl_Rating
    WHERE tbl_Rating.rated_to = U.user_id
);


--    FULL JOIN
--    Show all users and their customer records (if any). Include
--    users who are not customers and customers without a matching
--    user.
-- ------------------------------------------------------
SELECT U.user_id, C.default_payment_mode
FROM tbl_User U
FULL JOIN tbl_Customer C ON U.user_id = C.user_id;


-- =========================================
-- Count total trips per customer
-- =========================================
SELECT c.customer_id,
       u.full_name,
       COUNT(t.trip_id) AS completed_trip
FROM tbl_Customer c
JOIN tbl_User u ON c.user_id = u.user_id
JOIN tbl_Trip t ON c.customer_id = t.customer_id
GROUP BY c.customer_id, u.full_name
ORDER BY completed_trip DESC;

