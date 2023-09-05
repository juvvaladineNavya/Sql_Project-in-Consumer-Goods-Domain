#que 1
SELECT market FROM dim_customer WHERE customer = "Atliq Exclusive" AND region = "APAC" GROUP BY market;
# Que 2
SELECT X1.A AS unique_products_2020, X2.B AS unique_products_2021 , ((B-A)/A)*100 AS percentage_chg FROM(
(SELECT COUNT(DISTINCT(product_code)) AS A FROM fact_sales_monthly
      WHERE fiscal_year = 2020 ) As X1,
      (SELECT COUNT(DISTINCT(product_code)) AS B FROM fact_sales_monthly
      WHERE fiscal_year = 2021) As X2);
      # Que 3
SELECT segment, COUNT(DISTINCT(product)) AS product_count  
FROM dim_product 
GROUP BY segment
ORDER BY product_count DESC;
		#Que 4
SELECT CTE1.A AS segment, CTE1. B AS product_count_2020, CTE2. D AS product_count_2021 , (CTE2.D-CTE1.B) AS Difference 
FROM
(SELECT  (Segment ) AS A, COUNT(DISTINCT(pro.product_code)) AS B
FROM   dim_product AS Pro JOIN fact_sales_monthly AS Sal
ON pro.product_code = sal.product_code 
WHERE fiscal_year = 2020
GROUP BY sal.fiscal_year, pro.segment
ORDER BY Segment
) AS CTE1,
(SELECT  (Segment ) AS C, COUNT(DISTINCT(pro.product_code)) AS D
FROM   dim_product AS Pro JOIN fact_sales_monthly AS Sal
ON pro.product_code = sal.product_code 
WHERE fiscal_year = 2021
GROUP BY sal.fiscal_year, pro.segment
ORDER BY Segment
) AS CTE2
WHERE CTE1.A = CTE2.C;
# Que 5
(SELECT pro.product_code ,product , manufacturing_cost FROM dim_product pro , fact_manufacturing_cost MC 
WHERE pro.product_code = MC. product_code
ORDER BY  manufacturing_cost DESC LIMIT 1)
UNION
(SELECT pro.product_code ,product , manufacturing_cost FROM dim_product pro , fact_manufacturing_cost MC 
WHERE pro.product_code = MC. product_code
ORDER BY  manufacturing_cost ASC LIMIT 1);
#Que 6
WITH TBL1 AS
(SELECT customer_code AS A , AVG(pre_invoice_discount_pct) AS B 
FROM fact_pre_invoice_deductions WHERE fiscal_year = '2021'
GROUP BY customer_code),
TBL2 AS
(SELECT customer_code AS C, Customer AS D
	FROM dim_customer WHERE market = "India")
    
SELECT TBL1.A AS  customer_code, TBL2.D AS Customer, TBL1.B AS average_discount_percentage
FROM TBL1 JOIN TBL2 
ON TBL1.A = TBL2.C
ORDER BY average_discount_percentage DESC 
LIMIT 5;
#Que 7
SELECT MONTHNAME(FS.date) AS month,  FS.fiscal_year,
       ROUND(SUM(G.gross_price*FS.sold_quantity), 2) AS Gross_sales_Amount
FROM fact_sales_monthly FS JOIN dim_customer C ON FS.customer_code = C.customer_code
						   JOIN fact_gross_price G ON FS.product_code = G.product_code
WHERE C.customer = 'Atliq Exclusive'
GROUP BY  Month, FS.fiscal_year 
ORDER BY FS.fiscal_year ;
#Que 8
SELECT 
CASE
    WHEN date BETWEEN '2019-09-01' AND '2019-11-01' then CONCAT('[',1,'] ',MONTHNAME(date))  
    WHEN date BETWEEN '2019-12-01' AND '2020-02-01' then CONCAT('[',2,'] ',MONTHNAME(date))
    WHEN date BETWEEN '2020-03-01' AND '2020-05-01' then CONCAT('[',3,'] ',MONTHNAME(date))
    WHEN date BETWEEN '2020-06-01' AND '2020-08-01' then CONCAT('[',4,'] ',MONTHNAME(date))
    END AS Quarters,
    SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarters
#Que 9
WITH Output AS
(
SELECT C.channel,
       ROUND(SUM(G.gross_price*FS.sold_quantity/1000000), 2) AS Gross_sales_mln
FROM fact_sales_monthly FS JOIN dim_customer C ON FS.customer_code = C.customer_code
						   JOIN fact_gross_price G ON FS.product_code = G.product_code
WHERE FS.fiscal_year = 2021
GROUP BY channel
)
SELECT channel, CONCAT(Gross_sales_mln,' M') AS Gross_sales_mln , CONCAT(ROUND(Gross_sales_mln*100/total , 2), ' %') AS percentage
FROM
(
(SELECT SUM(Gross_sales_mln) AS total FROM Output) A,
(SELECT * FROM Output) B
)
ORDER BY percentage DESC 
#Que 9

WITH temp_table AS 
(
   SELECT c.channel, sum(m.sold_quantity*p.gross_price) as total_sales 
     FROM fact_sales_monthly m 
     JOIN fact_gross_price p
     ON m.product_code = p.product_code
     JOIN dim_customer c 
     ON m.customer_code = c.customer_code
     WHERE m.fiscal_year = 2021
     GROUP BY c.channel 
     ORDER BY total_sales DESC
)
SELECT channel , 
    ROUND(total_sales/1000000,2) as gross_sales_in_million,
    ROUND(total_sales/ (sum(total_sales) OVER()) *100,2)
AS Percentage 
FROM temp_table ;  
#Que 10
WITH Output1 AS 
(
SELECT P.division, FS.product_code, P.product, SUM(FS.sold_quantity) AS Total_sold_quantity
FROM dim_product P JOIN fact_sales_monthly FS
ON P.product_code = FS.product_code
WHERE FS.fiscal_year = 2021 
GROUP BY  FS.product_code, division, P.product
),
Output2 AS 
(
SELECT division, product_code, product, Total_sold_quantity,
        RANK() OVER(PARTITION BY division ORDER BY Total_sold_quantity DESC) AS 'Rank_Order' 
FROM Output1
)
 SELECT Output1.division, Output1.product_code, Output1.product, Output2.Total_sold_quantity, Output2.Rank_Order
 FROM Output1 JOIN Output2
 ON Output1.product_code = Output2.product_code
WHERE Output2.Rank_Order IN (1,2,3)
	
      