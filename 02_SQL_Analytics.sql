--1-What is the total number of transactions and what is the date range of the dataset?
SELECT 
	COUNT(*) AS total_purchases, 
	MIN(invoice_date) AS first_purchase, 
	MAX(invoice_date) AS last_purchase
FROM OnlineRetail_cleaned;

--2-What are the total revenue generated and the average transaction value across all records?
SELECT 
	SUM(total_price) AS total_revenue, 
	ROUND(AVG(total_price),2) AS averege_transaction
FROM OnlineRetail_cleaned;

--3-Which are the top 5 products based on the total quantity sold, and how can we rank them?
SELECT TOP 5 
	stock_code AS top_populars, 
	description, 
	SUM(quantity) AS total_quantity_sold
FROM OnlineRetail_cleaned
GROUP BY stock_code, description
ORDER BY total_quantity_sold DESC;

--4-Which are the top 5 countries that contribute the most to the total revenue, and how much percentage of the total revenue do they constitute?
SELECT TOP 5 
	country,
	SUM(total_price) AS country_revenue,
	ROUND((SUM(total_price) * 100.0 / SUM(SUM(total_price)) OVER ()),2) AS country_percentage_contribution
FROM OnlineRetail_cleaned
GROUP BY country
ORDER BY country_revenue DESC;

--5-What is the total number of unique customers that exist in the dataset?
SELECT 
	COUNT(DISTINCT customer_id) AS unique_customer_totals
FROM OnlineRetail_cleaned;

--6-What is the average number of transactions (invoices) made per customer?

WITH CustomerFrequency AS(
	SELECT 
		customer_id,
		COUNT(invoice_no) AS customer_AVG
	FROM OnlineRetail_cleaned
	GROUP BY customer_id
)
SELECT
	AVG(customer_AVG) AS average_transactions_per_customer
FROM CustomerFrequency;

--7-Which are the top 5 product descriptions that generate the highest total revenue?
SELECT TOP 5
	stock_code,
	description,
	ROUND(SUM(total_price),2) AS product_total_revenue
FROM OnlineRetail_cleaned
GROUP BY stock_code, description
ORDER BY product_total_revenue DESC;

--8-What is the maximum (most recent) invoice date in the dataset, and how can we use this to define our analysis date?

SELECT
	MAX(invoice_date) AS latest,
	DATEADD (day,1,MAX(invoice_date))AS Analysis_Date
FROM OnlineRetail_cleaned

 
--9-How many days ago did each customer make their most recent purchase, calculated against the predefined Analysis Date?
--defining a date variable (1 day after the latest invoice_date)
DECLARE @Analysis_Date DATE = '2011-12-10' 
SELECT 
	customer_id,
	DATEDIFF(day,MAX(invoice_date),@Analysis_Date) AS Recency
FROM OnlineRetail_cleaned
GROUP BY customer_id
ORDER BY Recency;

--10-How can we calculate the Recency, Frequency, and Monetary metrics for every single customer in one comprehensive query?

DECLARE @Analysis_Date DATE = '2011-12-10'; 
WITH RFM_Metrics AS 
(
	SELECT
		customer_id,
		DATEDIFF(day, MAX(invoice_date), @Analysis_Date) AS Recency,
		COUNT(DISTINCT invoice_no) AS Frequency,
		SUM(total_price) AS Monetary
	FROM OnlineRetail_cleaned
	GROUP BY customer_id
)
SELECT
	customer_id,
	Recency, 
	Frequency, 
	Monetary, 
	NTILE (5) OVER (ORDER BY Recency DESC) AS R_Score,
	NTILE (5) OVER (ORDER BY Frequency ASC) AS F_Score,
	NTILE (5) OVER (ORDER BY Monetary ASC) AS M_Score
FROM RFM_Metrics
ORDER BY customer_id;

--11-How can we combine the R, F, and M scores into a single RFM_Score and assign descriptive segment names to these scores?
SELECT
    customer_id,
    R_Score,
    F_Score,
    M_Score,
    CAST(R_Score AS varchar) + CAST(F_Score AS varchar) + CAST(M_Score AS varchar) AS RFM_Score
FROM RFM_scores;

--12-How can we combine the R, F, and M scores into a single RFM_Score and assign descriptive segment names to these scores?
WITH RFM_CTE AS(
	SELECT 
		customer_id,
		R_Score,
		F_Score,
		M_Score,
		CAST(R_Score AS varchar)+	CAST(F_Score AS varchar)+	CAST(M_Score AS varchar) AS RFM
	FROM RFM_scores
)
SELECT
	customer_id,
	RFM,
	CASE
		WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'Champions'
		WHEN R_Score >= 3 AND F_Score >= 3 THEN 'Loyal Customers'
		WHEN R_Score >= 4 AND F_Score <= 2 AND M_Score <= 2 THEN 'New Customers'
		WHEN R_Score <= 2 AND F_Score >= 4 AND M_Score >= 4 THEN 'Can’t Lose Them'
		WHEN R_Score <= 2 AND F_Score >= 3 THEN 'At Risk'
		WHEN R_Score <= 2 AND F_Score <= 2 AND M_Score <= 2 THEN 'Hibernating'
		ELSE 'Needs Attention'
  END AS Segment
FROM RFM_CTE
ORDER BY Segment ASC;