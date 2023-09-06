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

SELECT
    O.city_code,
    SUM(CASE WHEN (B.is_bundled = 'TRUE' AND B.is_unbundled = 'FALSE') THEN 1 ELSE 0 END) AS bundled_count,
    COUNT(*) AS total_count,
    (SUM(CASE WHEN (B.is_bundled = 'TRUE' AND B.is_unbundled = 'FALSE') THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS percentage_bundled
FROM Orders.Orders as O
LEFT JOIN Orders.Bundled_Orders as B
ON (O.order_id = B.order_id)
WHERE (city_code = 'GLV' OR city_code = 'PLY')
    AND creation_time >= '2021-11-01 00:00:00'
    AND creation_time <= '2021-11-01 23:59:59'
GROUP BY city_code;



/* Question B) 
Average courier speed:
1. From pickup time to delivery time for each city in the last 30 days
2. If a order is bundled consider the traject only to the first delivery (from pickup to first delivery)
3. pd_dist -> distance from pickup to delivery
*/

WITH AUX AS(
SELECT
        O.order_id,
        O.city_code,
        O.pd_dist AS distance_to_delivery,
        O.pickup_time,
        O.enters_delivery,
        B.bundle_id,
        B.is_bundled,
        B.is_unbundled,
        DATEDIFF(SECOND, O.pickup_time, O.enters_delivery) AS seconds_to_delivery, -- Gets the time to deliver
        CASE WHEN (B.is_bundled = 'TRUE' AND B.is_unbundled = 'FALSE') THEN MIN(O.pd_dist) OVER (PARTITION BY B.bundle_id) -- If an order is bundled compute the minimum distance per bundle_id
        ELSE MIN(O.pd_dist) OVER (PARTITION BY O.order_id) -- if a order is not bundled compute the minimum distance per order_id
        END AS min_distance

    FROM Orders.Orders AS O
    LEFT JOIN Orders.Bundled_Orders AS B
    ON (O.order_id = B.order_id)
    WHERE final_status = 'DeliveredStatus' -- Exclude orders without delivery timestamp
    AND pickup_time >= DATEADD(DAY, -30, '2021-11-30') -- Last 30 days (GETDATE() function should be used in production environment, I've only used '2021-11-30' as a static input to use the values given as example)
)

SELECT 
    city_code,
    AVG(min_distance) AS average_distance,
    AVG(seconds_to_delivery) AS average_seconds_to_deliver,
    CASE WHEN AVG(seconds_to_delivery) > 0 THEN ROUND(CAST(AVG(min_distance) AS FLOAT) / CAST(AVG(seconds_to_delivery) AS FLOAT) * 3.6, 2) ELSE NULL END AS average_speed_kmph

FROM AUX
GROUP BY city_code
ORDER BY (AVG(min_distance) / AVG(seconds_to_delivery)) * 3.6 DESC


