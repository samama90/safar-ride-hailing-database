# safar-ride-hailing-database
Designed and implemented a fully normalized 
relational database for a ride-hailing platform 
inspired by InDrive and Yango, as part of my 
4th Semester DBMS course at Bahria University 
Lahore.

DATABASE DESIGN:
- 12-table normalized schema with User 
  specialization hierarchy (Customer, Driver, Admin)
- Full EERD with cardinalities and constraints
- Named FKs, CHECK validations, referential integrity

SQL DEVELOPMENT:
- 40+ queries — JOINs (INNER, LEFT, RIGHT, FULL, SELF)
- Subqueries (IN, NOT IN, ANY, ALL, EXISTS, NOT EXISTS)
- Window functions (DENSE_RANK, RANK, ROW_NUMBER)
- DDL: CREATE, ALTER, TRUNCATE, DROP
- DML: INSERT, UPDATE, DELETE (Hard + Soft)

ADVANCED SQL:
- Scalar Functions for reusable business logic
- Table-Valued Functions for reporting
- Stored Procedures (Non-Parametric, Parametric,
  IF-ELSE + WHILE loop logic)
- Transactions + Triggers

REAL-WORLD SCENARIOS:
- Customer Lifetime Value (CLV) Ranking
- Driver Cancellation Rate Analysis
- Payment Method Trend — Monthly Pivot Table
- Churn Risk Detection (30-day inactivity)
- Trip Duration Anomaly Detection
- Payments Reconciliation — FULL JOIN
- Nearest Available Driver Detection
- License Expiry + Inactivity Risk Alert
- Bidirectional Rating System
  (Customer rates Driver + Driver rates Customer)
- Commission Tracking per completed trip
