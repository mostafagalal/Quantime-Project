-- Checking the dataset 
SELECT
*
FROM sales_1;
-- Checking for the index found that we have no index in the SCHEMAS tap
-- Checking the InvoiceNo column if it has duplicated values 
SELECT 
COUNT(*) - COUNT(DISTINCT invoiceno)
FROM 
sales_1;
/* We have some issues in DATA_TYPES in some columns such as the below
InvoiceDate = text / CustomerId = it has '.0' at the end / ShippingCost = text & null values // Discount column has a lot of no after decimal point
*/ 
-- Checking if we have multible lengths in CustomerId column
SELECT 
LENGTH (CUSTOMERID) AS LEN ,
COUNT(*)
FROM sales_1
GROUP BY LEN;
-- removing '.0' from CustomerId
UPDATE sales_1
SET customerid = TRIM(TRAILING '.0' FROM customerid)
WHERE customerid LIKE '%.0';
-- Checking if it goes well
SELECT 
customerid
FROM sales_1;
-- HANDLING THE NULL values as it doesn't have a shippingcost till we figure something else
UPDATE sales_1
SET shippingcost = 
CASE 
WHEN shippingcost = "" THEN 1
WHEN shippingcost IS NULL THEN 1
ELSE TRIM(shippingcost)
END 
WHERE shippingcost = "" OR shippingcost IS NULL;
-- As we need an accurate number we will use decimal instead of double
ALTER TABLE sales_1 MODIFY COLUMN shippingcost DECIMAL(4,2);
-- After checking the invoicedate found that everyday the time changes in 1 hour in a row 
-- So there is no need of the time as it doesn't represent anything
SELECT 
COUNT(*) - COUNT(DISTINCT invoicedate)
FROM sales_1;
-- Deleting the time from the invoicedate 
UPDATE sales_1
SET invoicedate = TRIM(LEFT(invoicedate , 10));
-- Chaning the data type from TEXT to date
ALTER TABLE sales_1 MODIFY COLUMN invoicedate DATE;
-- Handling the fraction Number after the decimal point in Discount Column 
SELECT
LENGTH(discount) AS LEN ,
Count(discount)
FROM sales_1
GROUP BY LEN;
-- After checking found that most of them 4 characters so we will decrease the no to 4 charchter & 2 after decimal point 
ALTER TABLE sales_1 MODIFY COLUMN discount DECIMAL(4,2);

-- Describe to check the datatypes of all the columns 
DESCRIBE sales_1;
-- So from here all the DataTypes are good

-- How many values that discount is >= to 100 and that is invalid
SELECT
COUNT(*)
FROM sales_1
WHERE discount >= 1;
-- How many the unitprice is < 0 and that's invalid
SELECT
COUNT(*)
FROM sales_1
WHERE UnitPrice < 0;
-- Found out that UnitPrice < 0 , discount >= 1 , CustomerId is NULL , Quantity < 0 & ReturnStatus is NotReturned 
-- All of that are invalid and the count of them is ( 1493 ) so accoridng to our data they are not to many so we will drop these rows
DELETE FROM sales_1 Where UnitPrice < 0;
DELETE FROM sales_1 WHERE quantity < 1;

-- UNTILL NOW THE DATA IS READY **till we find something else we need to fix** 

-- 1- QUESTION, What is the highest & lowest orders per product in orders ?
-- Highest = WALL CLOCK - LOWEST = Wireless MOUSE
SELECT 
description, 
COUNT(description) AS Number_of_sales
FROM sales_1
GROUP BY description
ORDER BY Number_of_sales DESC;

-- 2- QUESTION, What is the most expensive and cheapest product ?
-- The most expensive = White Mug / The most cheapest = Notebook
SELECT 
description,
ROUND(SUM(unitprice),2) AS Price_per_product
FROM sales_1
GROUP BY description
ORDER BY Price_per_product DESC;

-- 3- Question, What is the most client has orders ?
-- Found that the most one has 6 orders & accoridng to the volume of the data it's not a big deal
-- Also found 3485 empty , But we won't remove them.
SELECT 
customerid,
COUNT(customerid) AS Customer_orders
FROM sales_1
GROUP BY customerid
ORDER BY Customer_orders DESC;

-- 4- Question, What is the highest country in orders ?
-- France is the highest one
SELECT 
Country,
COUNT(Country) AS Country_orders
FROM sales_1
GROUP BY Country
ORDER BY Country_orders DESC;

-- 5- Question, The Max & Min discount 
-- All products share the same Max & Min discounts
SELECT 
Description,
MAX(discount) AS Max,
MIN(discount) AS Min
FROM sales_1
GROUP BY Description;

-- 6- Question, The highest & lowest paymentgateway ?
-- No big difference but the highest is Bank Transfer
SELECT 
PaymentMethod,
COUNT(PaymentMethod) AS PaymentMethod_numbers
FROM sales_1
GROUP BY PaymentMethod
ORDER BY PaymentMethod_numbers DESC;

-- 7- Question The highest & lowest shipping cost ?
-- The highest is 30 , Lowest is 1
SELECT 
Round(MAX(shippingcost)) AS Max,
Round(MIN(shippingcost)) AS Min
FROM sales_1;

-- 8- Which paymentmethod is popular in which month & year ?
-- CHART - found decrease in the sales of 2025 
SELECT
paymentmethod,
DATE_FORMAT(invoicedate , '%Y-%m') AS Date,
COUNT(paymentmethod) AS Num_of_Payment
FROM sales_1
GROUP BY paymentmethod, Date
ORDER BY Date , Num_of_Payment;

-- 9- Question, Which payment method with every channel
-- CHART - No big difference has been found
SELECT 
paymentmethod,
saleschannel,
EXTRACT(YEAR FROM invoicedate) AS date,
COUNT(paymentmethod) AS Payment_No
FROM sales_1
GROUP BY paymentmethod, saleschannel,date
ORDER BY  date, Payment_No;

-- 10- QUESTION, Which shipment_provider has the highest 
-- CHART - There is a big decrease in 2025 maybe because 2025 data end in SEPTEMBER
SELECT 
ShipmentProvider,
EXTRACT(YEAR FROM invoicedate) AS date,
COUNT(ShipmentProvider) AS Shipment_No
FROM sales_1
GROUP BY ShipmentProvider,date
ORDER BY date, Shipment_No asc;

-- 11- QUESTION, Diffrentiate between orderpriority's count for every year
-- CHART - 
SELECT 
orderpriority,
DATE_FORMAT(invoicedate , '%Y') AS date,
COUNT(orderpriority) AS order_No
FROM sales_1
GROUP BY orderpriority,date;

-- 12- QUESTION, Divide every country with the highest payment method used
-- CHART -
WITH payment_per_country AS (
SELECT
country,
paymentmethod,
COUNT(paymentmethod) AS payment_no,
RANK() OVER (PARTITION BY country ORDER BY COUNT(paymentmethod) DESC ) AS RANKS
FROM sales_1
GROUP BY country, paymentmethod)
SELECT 
country,
paymentmethod,
payment_no
FROM payment_per_country
WHERE RANKS =  1
ORDER BY payment_no DESC;

-- 13- QUESTION, The most selling product as per quantity for 2020
-- Chart
SELECT
StockCode,
description,
country,
DATE_FORMAT(invoicedate , '%Y') AS date,
SUM(quantity) AS No_of_sales
FROM sales_1
GROUP BY StockCode, description, country, date
HAVING DATE = 2020
ORDER BY No_of_sales DESC;

-- 14- QUESTION, The most selling categories
-- CHART - Found that furniture is the most popular 
WITH MOST_CATEGORIES AS (
SELECT
category,
DATE_FORMAT(invoicedate , '%Y') AS date,
COUNT(category) AS Most_category,
RANK() OVER( PARTITION BY DATE_FORMAT(invoicedate , '%Y') ORDER BY COUNT(category) DESC ) AS freq
FROM sales_1
GROUP BY category,date )
SELECT 
* 
FROM MOST_CATEGORIES
WHERE freq = 1;

-- 15- QUESTION, The most selling category
-- CHART
SELECT
Category,
DATE_FORMAT(invoicedate , '%Y') AS Date,
ROUND(AVG(unitprice),2) AS avg_per_category
FROM sales_1
GROUP BY Category,Date;

-- 16-QUESTION, SUM & Number of unit sold per category per year
-- CHART
SELECT
Category,
COUNT(unitprice) AS no_of_unites,
ROUND(SUM(unitprice),2)AS total_sum_per_unit,
RANK() OVER( PARTITION BY DATE_FORMAT(invoicedate, "%Y")  ORDER BY ROUND(SUM(unitprice),2) DESC) AS RANKS,
DATE_FORMAT(invoicedate, "%Y") AS date
FROM sales_1
GROUP BY category, date;

-- 17-QUESTION, Average shipping cost per country
-- CHART 
WITH SHIPPING AS (
SELECT
country,
DATE_FORMAT(invoicedate , '%Y') AS date,
ROUND(AVG(Shippingcost),2) AS shipping_cost
from sales_1
GROUP BY country, date
)
SELECT 
*,
RANK() OVER( PARTITION BY date ORDER BY shipping_cost DESC )
FROM SHIPPING;

--
--

SELECT
saleschannel,
ReturnStatus,
COUNT(ReturnStatus),
DATE_FORMAT(invoicedate , '%Y') AS date
FROM sales_1
GROUP BY saleschannel,ReturnStatus, date
HAVING ReturnStatus = 'returned';


DESCRIBE SALES_1;



CREATE VIEW ORDERS AS
SELECT
saleschannel,
ReturnStatus
FROM sales_1;







