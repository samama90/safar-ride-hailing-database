Use PROJECT_SAFAR
--=====================================================--
--==================CREATE TABLES========================

CREATE TABLE tbl_User (
    user_id         INT PRIMARY KEY,
    full_name       NVARCHAR(100) NOT NULL,
    email           NVARCHAR(100) UNIQUE NOT NULL,
    phone           NVARCHAR(15)  UNIQUE NOT NULL,
    password_hash   NVARCHAR(255) NOT NULL,
    gender          NVARCHAR(1) CHECK (gender IN ('M', 'F', 'O')),
    cnic            NVARCHAR(15)  UNIQUE NOT NULL,
    profile_picture NVARCHAR(255),
    is_active       BIT DEFAULT 1,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    current_city    NVARCHAR(50)
);

------------CUSTOMER-------------------

CREATE TABLE tbl_Customer (
    customer_id          INT PRIMARY KEY,
    user_id              INT NOT NULL,
    default_payment_mode NVARCHAR(10) NOT NULL DEFAULT 'cash'
                         CHECK (default_payment_mode IN ('cash','card','wallet')),
    CONSTRAINT FK_Customer_User
    FOREIGN KEY (user_id) REFERENCES tbl_User (user_id),
    CONSTRAINT UQ_Customer_User
    UNIQUE (user_id)
);

--------------DRIVER------------------

CREATE TABLE tbl_Driver (
    driver_id             INT PRIMARY KEY,
    user_id               INT NOT NULL,
    license_number        NVARCHAR(20) NOT NULL UNIQUE,
    license_expiry        DATE NOT NULL,
    verified              BIT DEFAULT 0,
    joining_date          DATE NOT NULL,
    total_rides_completed INT DEFAULT 0,
    CONSTRAINT FK_Driver_User
    FOREIGN KEY (user_id) REFERENCES tbl_User (user_id),
    CONSTRAINT UQ_Driver_User
    UNIQUE (user_id)
);

---------------------ADMIN---------------------------

CREATE TABLE tbl_Admin (
    admin_id    INT IDENTITY(1,1) PRIMARY KEY,
    user_id     INT NOT NULL,
    role        NVARCHAR(20) NOT NULL
                CHECK (role IN ('super','mod','finance')),
    last_login  DATETIME,
    CONSTRAINT FK_Admin_User
    FOREIGN KEY (user_id) REFERENCES tbl_User (user_id),
    CONSTRAINT UQ_Admin_User
    UNIQUE (user_id)
);

-----------------Vehicle-----------------------

CREATE TABLE tbl_Vehicle (

    vehicle_id          INT PRIMARY KEY,
    driver_id           INT NOT NULL,
    manufacturer        NVARCHAR(50) NOT NULL,
    model               NVARCHAR(50) NOT NULL,
    color               NVARCHAR(30) NOT NULL,
    registration_number NVARCHAR(20) NOT NULL,

    type                NVARCHAR(20) NOT NULL
                        CHECK (type IN ('bike','car','auto','rickshaw')),

    seating_capacity    INT DEFAULT 4,
    registration_expiry DATE NOT NULL,
    insurance_expiry    DATE NOT NULL,

    CONSTRAINT FK_Vehicle_Driver
    FOREIGN KEY (driver_id) REFERENCES tbl_Driver(driver_id),

    CONSTRAINT UQ_Vehicle_RegNum
    UNIQUE (registration_number),

    CONSTRAINT CK_Vehicle_Seating
    CHECK (seating_capacity > 0)
);

-------------Location-----------------

CREATE TABLE tbl_Location (

    location_id   INT PRIMARY KEY,
    latitude      DECIMAL(10,8) NOT NULL,
    longitude     DECIMAL(11,8) NOT NULL,
    address_label NVARCHAR(255),
    area          NVARCHAR(100),
    city          NVARCHAR(50) NOT NULL,

    CONSTRAINT CK_Location_Latitude
    CHECK (latitude BETWEEN -90 AND 90),

    CONSTRAINT CK_Location_Longitude
    CHECK (longitude BETWEEN -180 AND 180)
);

---------------Trip----------------

CREATE TABLE tbl_Trip (
    trip_id               INT PRIMARY KEY,
    customer_id           INT NOT NULL,
    driver_id             INT NOT NULL,
    vehicle_id            INT NOT NULL,
    pickup_location_id    INT NOT NULL,
    dropoff_location_id   INT NOT NULL,
    distance_covered      DECIMAL(8,2) NOT NULL,
    fare_amount           DECIMAL(10,2) NOT NULL,

    trip_status           NVARCHAR(20) NOT NULL DEFAULT 'requested'
                          CHECK (trip_status IN ('requested','accepted','ongoing','completed','cancelled')),

    request_time          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    start_time            DATETIME,
    end_time              DATETIME,

    CONSTRAINT FK_Trip_Customer
    FOREIGN KEY (customer_id) REFERENCES tbl_Customer(customer_id)
    ON UPDATE CASCADE,

    CONSTRAINT FK_Trip_Driver
    FOREIGN KEY (driver_id) REFERENCES tbl_Driver(driver_id)
    ON UPDATE CASCADE,

    CONSTRAINT FK_Trip_Vehicle
    FOREIGN KEY (vehicle_id) REFERENCES tbl_Vehicle(vehicle_id)
    ON UPDATE CASCADE,

    CONSTRAINT FK_Trip_PickupLocation
    FOREIGN KEY (pickup_location_id) REFERENCES tbl_Location(location_id),

    CONSTRAINT FK_Trip_DropoffLocation
    FOREIGN KEY (dropoff_location_id) REFERENCES tbl_Location(location_id)
);

------------Payment-------------------

CREATE TABLE tbl_Payment (
    payment_id      INT PRIMARY KEY,
    trip_id         INT NOT NULL,
    amount          DECIMAL(10,2) NOT NULL,
    method          NVARCHAR(10) NOT NULL DEFAULT 'cash'
                    CHECK (method IN ('cash','card','wallet')),

    status          NVARCHAR(20) NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending','approved','failed','refunded')),

    transaction_id  NVARCHAR(100),
    payment_date    DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT UQ_Payment_Trip
    UNIQUE (trip_id),

    CONSTRAINT FK_Payment_Trip
    FOREIGN KEY (trip_id) REFERENCES tbl_Trip(trip_id)
    ON UPDATE CASCADE
);

--------------Rating----------------

CREATE TABLE tbl_Rating (
    rating_id    INT PRIMARY KEY,
    trip_id      INT NOT NULL,
    rated_by     INT NOT NULL,
    rated_to     INT NOT NULL,
    rating_value INT NOT NULL
    CHECK (rating_value BETWEEN 1 AND 5),

    comment      NVARCHAR(MAX),
    created_at   DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_Rating_Trip
    FOREIGN KEY (trip_id) REFERENCES tbl_Trip(trip_id)
    ON UPDATE CASCADE,

    CONSTRAINT FK_Rating_RatedBy
    FOREIGN KEY (rated_by) REFERENCES tbl_User(user_id),

    CONSTRAINT FK_Rating_RatedTo
    FOREIGN KEY (rated_to) REFERENCES tbl_User(user_id),

    CONSTRAINT UQ_Rating_Trip_Rater
    UNIQUE (trip_id, rated_by),

    CONSTRAINT CK_Rating_SelfRate
    CHECK (rated_by <> rated_to)
);

---------------Commission----------------

CREATE TABLE tbl_Commission (
    commission_id     INT PRIMARY KEY,
    trip_id           INT NOT NULL,
    rate_percentage   DECIMAL(5,2) NOT NULL,
    commission_amount DECIMAL(10,2) NOT NULL,
    effective_date    DATE NOT NULL,

    CONSTRAINT UQ_Commission_Trip
    UNIQUE (trip_id),

    CONSTRAINT FK_Commission_Trip
    FOREIGN KEY (trip_id) REFERENCES tbl_Trip(trip_id)
    ON UPDATE CASCADE,

    CONSTRAINT CK_Commission_Rate
    CHECK (rate_percentage BETWEEN 0 AND 100),

    CONSTRAINT CK_Commission_Amount
    CHECK (commission_amount > 0)
);

---------Route-------------

CREATE TABLE tbl_Route (
    route_id            INT PRIMARY KEY,
    trip_id             INT NOT NULL,
    estimated_distance  DECIMAL(8,2) NOT NULL,
    estimated_time      INT NOT NULL,
    actual_distance     DECIMAL(8,2),
    actual_time         INT,

    CONSTRAINT UQ_Route_Trip
    UNIQUE (trip_id),

    CONSTRAINT FK_Route_Trip
    FOREIGN KEY (trip_id) REFERENCES tbl_Trip(trip_id)
    ON UPDATE CASCADE,

    CONSTRAINT CK_Route_EstDistance
    CHECK (estimated_distance > 0),

    CONSTRAINT CK_Route_EstTime
    CHECK (estimated_time > 0),

    CONSTRAINT CK_Route_ActDistance
    CHECK (actual_distance IS NULL OR actual_distance > 0),

    CONSTRAINT CK_Route_ActTime
    CHECK (actual_time IS NULL OR actual_time > 0)
);

----------Trip history------------

CREATE TABLE tbl_Trip_History (
    history_id        INT PRIMARY KEY,
    trip_id           INT NOT NULL,
    status_changed_to NVARCHAR(20) NOT NULL
                      CHECK (status_changed_to IN ('requested','accepted','ongoing','completed','cancelled')),

    changed_at        DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT FK_TripHistory_Trip
    FOREIGN KEY (trip_id) REFERENCES tbl_Trip(trip_id)
);
