USE master
GO
IF NOT EXISTS (
 SELECT name
 FROM sys.databases
 WHERE name = N'Glovo_Fintech'
)
 CREATE DATABASE [Glovo_Fintech];
GO


USE Glovo_Fintech
GO

/* Create schema for Orders */
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Orders') -- Check if schema for Orders is not already created 
    BEGIN
        EXEC ('CREATE SCHEMA [Orders]'); -- Create schema for Orders if it does not exist already
    END

GO 

/* Creating Tables */
IF (EXISTS (SELECT * 
                 FROM sys.TABLES 
                 WHERE name in ('Orders', 'Bundled_Orders') -- Check if tables are already created
                ))
BEGIN
    DROP TABLE IF EXISTS [Orders].[Orders]
    DROP TABLE IF EXISTS [Orders].[Bundled_Orders]
END  
GO

-- TABLE Orders - Table with info about Orders
CREATE TABLE [Orders].Orders (
    order_id VARCHAR(255) PRIMARY KEY,
    city_code VARCHAR(10),
    store_id VARCHAR(255),
    creation_time DATETIME,
    pickup_time DATETIME,
    enters_delivery DATETIME,
    pd_dist INT,
    final_status VARCHAR(255)
);

-- TABLE Bundled_Orders - Table with info about Orders that are Bundled together
CREATE TABLE [Orders].Bundled_Orders (
    order_id VARCHAR(255),
    bundle_id VARCHAR(255),
    is_bundled VARCHAR(10),
    is_unbundled VARCHAR(10)
);

GO

INSERT INTO [Orders].Orders (order_id, city_code, store_id, creation_time, pickup_time, enters_delivery, pd_dist, final_status)
VALUES
    ('4596184593', 'AMS', '3372', '2021-11-01 23:23:04', '2021-11-01 23:33:52', '2021-11-01 23:43:17', 1503, 'DeliveredStatus'),
    ('4569203459', 'GLV', '8844', '2021-11-02 11:13:23', NULL, NULL, 2004, 'CanceledStatus'),
    ('4596020394', 'GLV', '99103', '2021-11-01 20:56:01', '2021-11-01 21:03:22', '2021-11-01 21:11:20', 1842, 'DeliveredStatus'),
    ('4592303948', 'PLY', '12287', '2021-11-01 16:49:18', '2021-11-01 16:55:05', '2021-11-01 16:55:35', 5, 'DeliveredStatus'),
    ('4592303949', 'PLY', '12287', '2021-11-01 16:50:30', '2021-11-01 16:59:45', '2021-11-01 17:12:48', 1562, 'DeliveredStatus');


INSERT INTO [Orders].Bundled_Orders (order_id, bundle_id, is_bundled, is_unbundled)
VALUES
    ('4395449294', '87632847', 'TRUE', 'FALSE'),
    ('4596020394', '87632847', 'TRUE', 'FALSE'),
    ('4339452836', '87632239', 'TRUE', 'TRUE'),
    ('4592303948', '87632239', 'TRUE', 'TRUE'),
    ('4395529454', '87633554', 'TRUE', 'FALSE');




/* Question A) */

WITH BundledOrders AS (
    SELECT DISTINCT o1.order_id
    FROM Orders.Orders o1
    JOIN Orders.Bundled_Orders b ON o1.order_id = b.order_id
    WHERE o1.city_code = 'GLV' OR o1.city_code = 'PLY'
    AND o1.creation_time >= '2021-11-01 00:00:00'
    AND o1.creation_time <= '2021-11-01 23:59:59'
    AND b.is_bundled = 'TRUE'
    AND b.is_unbundled = 'FALSE'
),
TotalOrders AS (
    SELECT DISTINCT o2.order_id, o2.city_code
    FROM Orders.Orders o2
    WHERE (o2.city_code = 'GLV' OR o2.city_code = 'PLY')
    AND o2.creation_time >= '2021-11-01 00:00:00'
    AND o2.creation_time <= '2021-11-01 23:59:59'
)
SELECT
    t.city_code,
    COUNT(DISTINCT bo.order_id) AS bundled_count,
    COUNT(DISTINCT t.order_id) AS total_count,
    (COUNT(DISTINCT bo.order_id) * 100.0 / COUNT(DISTINCT t.order_id)) AS percentage_bundled
FROM TotalOrders t
LEFT JOIN BundledOrders bo ON t.order_id = bo.order_id
GROUP BY t.city_code;