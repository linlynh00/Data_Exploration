--- Tao table tong hop 3 nam
Drop table if exists #sales_1517
CREATE TABLE #sales_1517
(
    OrderDate DATETIME2(7) NOT NULL,
    StockDate DATETIME2(7) NOT NULL,
    OrderNumber NVARCHAR(50) NOT NULL,
    ProductKey SMALLINT NOT NULL,
    CustomerKey SMALLINT NOT NULL,
    TerritoryKey TINYINT NOT NULL,
    OrderLineItem TINYINT NOT NULL,
    OrderQuantity TINYINT NOT NULL
)

INSERT INTO #sales_1517
SELECT * FROM dbo.Sales_2017
    UNION 
    SELECT * FROM dbo.Sales_2016
    UNION
    SELECT * FROM dbo.Sales_2015

---------------
---Tinh tong revenue, cost, profit tung thang trong 3 nam

select  DATETRUNC(month, #sales_1517.orderdate) as monthyear, 
    sum(orderquantity*productprice) as revenue,
    sum(orderquantity*productcost) as cost,
    (sum(orderquantity*productprice)-sum(orderquantity*productcost)) as profit
from #sales_1517
join dbo.Products
on dbo.Products.productkey = #sales_1517.productkey
group by DATETRUNC(month, #sales_1517.orderdate)
ORDER by monthyear 

-------------------
-- Tinh sales_qty va returns_qty tung thang cua tung product key (Purpose: Tinh doanh thu/Loi nhuan rong)

WITH total_sales AS -- Lay so sales_qty tung thang cua tung san pham
(
SELECT  p.productkey s_productkey, 
        DATETRUNC(month,s.orderdate) AS month_sales,
        SUM(s.orderquantity) AS total_qty_sales, 
        p.ProductPrice, P.ProductCost
FROM dbo.products p 
    JOIN #sales_1517 s ON s.productkey = p.productkey 
    GROUP BY DATETRUNC(month,s.orderdate), p.productkey,p.ProductPrice, P.ProductCost
)

SELECT total_sales.month_sales, 
    total_sales.s_productkey,
    total_returns.total_qty_returns,
    total_sales.total_qty_sales,
    total_sales.ProductPrice,
    total_sales.ProductCost
FROM total_sales 
JOIN 
    ( -- Lay returns_qty tung thang cua tung san pham 
    SELECT p.productkey AS r_productkey, 
        DATETRUNC(month,r.returndate) AS month_returns,
        SUM(r.ReturnQuantity) AS total_qty_returns
    FROM dbo.products p
    JOIN dbo.Returns r ON r.productkey = p.productkey
    GROUP BY DATETRUNC(month,r.returndate), p.productkey
    ) AS total_returns 
ON total_sales.month_sales = total_returns.month_returns
    AND s_productkey = r_productkey
ORDER BY month_sales 

-----------------
 -- Tinh so transactions cua tung khach hang qua tung nam
SELECT DATEPART(year, orderdate) AS year,
    s.CustomerKey,
    COUNT(*) as total_transaction
FROM #sales_1517 s  
JOIN Customers c 
ON c.CustomerKey = s.CustomerKey
GROUP BY  DATEPART(year, orderdate), s.CustomerKey
ORDER BY 3 DESC

 -- Tinh Tong chi tieu va xep hang khach hang theo chi tieu moi nam 

WITH sub AS
( -- Chi tieu cua tung khach hang cho tung san pham trong nam
SELECT DATEPART(year, orderdate) AS year, 
        s.CustomerKey, s.ProductKey,
        s.OrderQuantity * p.ProductPrice AS consume_per_product
FROM #sales_1517 s 
JOIN Products p ON s.ProductKey = p.ProductKey
)
SELECT year,
        CustomerKey,
        sum(consume_per_product) as total_consume,
        rank() OVER (PARTITION BY year ORDER BY sum(consume_per_product) DESC) AS Rank
FROM sub 
GROUP BY year, CustomerKey
ORDER BY 1 DESC

---------------
-- Tinh so khach hang nam/nu tung nam 
SELECT year, Gender,
    COUNT(*) as numbers_of_customer
FROM 
(
SELECT DISTINCT DATEPART(year, s.orderdate) year,
    s.CustomerKey, c.Gender
FROM Customers c 
JOIN #sales_1517 s ON c.CustomerKey = s.CustomerKey 
Where Gender is not NULL) as sub 
GROUP BY year, gender
ORDER BY year, gender 
