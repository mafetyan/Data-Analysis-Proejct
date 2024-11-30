--	1)	Which product category has the highest revenue?

SELECT PC.name AS productcategory, SUM(OrderQty*UnitPrice) AS TotalRevenue
FROM Production.Product PD 
INNER JOIN Production.ProductSubcategory PS ON PD.ProductSubcategoryID = PS.ProductSubcategoryID 
INNER JOIN Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID
INNER JOIN Sales.SalesOrderDetail SOD ON PD.ProductID = SOD.ProductID
GROUP BY PC.name
ORDER BY TotalRevenue desc
;


--
SELECT YEAR(soh.OrderDate) AS Year, MONTH(soh.OrderDate) AS Month, COUNT(soh.SalesOrderID) AS TotalOrders
FROM Sales.SalesOrderHeader SOH
WHERE YEAR(soh.OrderDate) = 2014
GROUP BY YEAR(soh.OrderDate), MONTH(soh.OrderDate)
ORDER BY Year, Month;

---
SELECT 
    YEAR(soh.OrderDate) AS Year, 
    DATEPART(QUARTER, soh.OrderDate) AS Quarter, 
    SUM(sod.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY YEAR(soh.OrderDate), DATEPART(QUARTER, soh.OrderDate)
ORDER BY TotalRevenue DESC;

--	2)	Sales performance difference from online and instore

SELECT    CASE        WHEN OnlineOrderFlag = 1 THEN 'Online Store'        ELSE 'Physical Store'    END AS StoreType, 	COUNT(SalesOrderID) AS TotalOrders, SUM(TotalDue) AS TotalSales, AVG(TotalDue) AS AverageOrderValueFROM Sales.SalesOrderHeaderGROUP BY OnlineOrderFlag;--	3)	Who is sales persons which have the highest sales. Compare in region (territory)SELECT TOP 5 SP.BusinessEntityID, P.FirstName, P.LastName, ST.Name AS Territory_Name, SUM(sod.LineTotal) AS Total_SalesFROM Sales.SalesOrderHeader SOHJOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderIDJOIN Sales.SalesPerson SP ON SP.BusinessEntityID = SOH.SalesPersonIDJOIN Sales.SalesTerritory ST ON SOH.TerritoryID = ST.TerritoryIDJOIN Person.Person p ON SP.BusinessEntityID = P.BusinessEntityIDGROUP BY SP.BusinessEntityID, P.FirstName, P.LastName, ST.NameORDER BY Total_Sales DESC;--	4)	Trendline for sales between 2 years for top selling product.

SELECT MIN(OrderDate), MAX(OrderDate)
FROM Sales.SalesOrderHeader
;

WITH TopProducts AS (
    SELECT TOP 3 SOD.ProductID, SUM(sod.LineTotal) AS TotalSales
    FROM Sales.SalesOrderDetail SOD
    JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
    WHERE YEAR(SOH.OrderDate) BETWEEN 2012 AND 2013
    GROUP BY SOD.ProductID
    ORDER BY TotalSales DESC

)
SELECT PD.Name AS ProductName, YEAR(SOH.OrderDate) AS SalesYear, MONTH(SOH.OrderDate) AS SalesMonth, SUM(SOD.LineTotal) AS MonthlySales
FROM Sales.SalesOrderDetail SOD
JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
JOIN Production.Product PD ON SOD.ProductID = PD.ProductID
JOIN TopProducts TP ON SOD.ProductID = TP.ProductID
WHERE YEAR(SOH.OrderDate) BETWEEN 2012 AND 2013
GROUP BY PD.Name, YEAR(SOH.OrderDate), MONTH(SOH.OrderDate)
ORDER BY PD.Name, SalesYear, SalesMonth
; 

--	5)	Which regions is affecting total revenue

SELECT ST.Name AS Region, SUM(SOH.TotalDue) AS TotalRevenue
FROM Sales.SalesOrderHeader AS SOH
JOIN Sales.SalesTerritory AS ST ON SOH.TerritoryID = ST.TerritoryID
GROUP BY ST.Name
ORDER BY TotalRevenue DESC
;

--	6)	Discount or offers relation to sales.

SELECT 
    CASE 
        WHEN SOD.UnitPriceDiscount > 0 THEN 'Discounted'
        ELSE 'Non-Discounted'
    END AS DiscountType,
    SUM(SOD.LineTotal) AS TotalSales, COUNT(SOH.SalesOrderID) AS TotalOrders, AVG(SOD.LineTotal) AS AverageOrderValue
FROM Sales.SalesOrderDetail SOD
JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
GROUP BY CASE 
			WHEN SOD.UnitPriceDiscount > 0 THEN 'Discounted'
			ELSE 'Non-Discounted'
		 END
ORDER BY  DiscountType
;

--	7)	Average order size for each category.

SELECT PC.Name, AVG(SOD.OrderQty) as Average_Order_Size
FROM Sales.SalesOrderDetail SOD
JOIN Production.Product P ON SOD.ProductID = P.ProductID
JOIN Production.ProductSubcategory PS ON P.ProductSubcategoryID = PS.ProductSubcategoryID
JOIN Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID
GROUP BY Pc.Name
ORDER BY Average_Order_Size DESC
;

--	8)	Loyalty program and relation with customers volume and orders volume

WITH CustomerOrders AS (
    SELECT soh.CustomerID, COUNT(soh.SalesOrderID) AS OrderCount
    FROM Sales.SalesOrderHeader soh
    GROUP BY soh.CustomerID
)
SELECT 
    CASE 
        WHEN co.OrderCount = 1 THEN 'One-Time Customer'
		WHEN co.OrderCount > 1 AND co.OrderCount<= 10 THEN 'Occasional Customer'
        ELSE 'Frequent Customer'
    END AS CustomerType,
    COUNT(co.CustomerID) AS CustomerVolume, SUM(co.OrderCount) AS OrderVolume
FROM CustomerOrders co
GROUP BY CASE 
        WHEN co.OrderCount = 1 THEN 'One-Time Customer'
		WHEN co.OrderCount > 1 AND co.OrderCount<= 10 THEN 'Occasional Customer'
        ELSE 'Frequent Customer'
    END
ORDER BY OrderVolume DESC;
;

--	9)	Which products which people often purchase together?

WITH OrderProducts AS (
    SELECT sod.SalesOrderID, sod.ProductID
    FROM Sales.SalesOrderDetail sod
)

SELECT TOP 10 p1.Name AS Product1, p2.Name AS Product2, COUNT(*) AS PairCount
FROM OrderProducts op1
JOIN OrderProducts op2 ON op1.SalesOrderID = op2.SalesOrderID
JOIN Production.Product p1 ON op1.ProductID = p1.ProductID
JOIN Production.Product p2 ON op2.ProductID = p2.ProductID
WHERE op1.ProductID < op2.ProductID  -- Avoid duplicate and self-pairing
GROUP BY p1.Name, p2.Name
ORDER BY PairCount DESC
;

--	10)	Seasonality, pattern Sales for different products for each season

SELECT PD.Name AS Product_Name, YEAR(SOH.OrderDate) AS Sales_Year, MONTH(SOH.OrderDate) AS Sales_Month, SUM(SOD.LineTotal) AS Total_Sales
FROM Sales.SalesOrderDetail SOD
JOIN Sales.SalesOrderHeader SOH ON SOD.SalesOrderID = SOH.SalesOrderID
JOIN Production.Product PD ON SOD.ProductID = PD.ProductID
GROUP BY PD.Name, YEAR(SOH.OrderDate), MONTH(SOH.OrderDate)
ORDER BY Product_Name, Sales_Year, Sales_Month
;

--	11)	Average delivery time for online products

SELECT AVG(DATEDIFF(DAY, OrderDate, ShipDate)) AS Average_Delivery_Time
FROM Sales.SalesOrderHeader 
WHERE OnlineOrderFlag = 1 AND ShipDate IS NOT NULL
;

--	12)	Impact of delivery time on customer

WITH DeliveryTimes AS (
    SELECT soh.CustomerID, AVG(DATEDIFF(day, soh.OrderDate, soh.ShipDate)) AS AvgDeliveryTime
    FROM Sales.SalesOrderHeader soh
    WHERE soh.ShipDate IS NOT NULL
    GROUP BY soh.CustomerID
),
CustomerOrders AS (
    SELECT soh.CustomerID, COUNT(soh.SalesOrderID) AS OrderCount
    FROM Sales.SalesOrderHeader soh
    GROUP BY soh.CustomerID
)
SELECT DISTINCT dt.AvgDeliveryTime, co.OrderCount,
    CASE 
        WHEN co.OrderCount = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS CustomerType
FROM DeliveryTimes dt
JOIN CustomerOrders co ON dt.CustomerID = co.CustomerID
ORDER BY dt.AvgDeliveryTime;

--	13)	A3la products people rg3oha and reason



--	14)	A3la products or categories in profit margin

SELECT TOP 10 PD.Name AS Product_Name, PD.ListPrice, PD.StandardCost, ((PD.ListPrice-PD.StandardCost)/PD.ListPrice)*100 AS Profit_Margin
FROM Production.Product PD
WHERE ListPrice > 0
ORDER BY Profit_Margin DESC, ListPrice DESC, StandardCost DESC
;

SELECT PC.Name AS Category_Name, AVG((PD.ListPrice - PD.StandardCost)/PD.ListPrice)*100 AS AVG_Profit_Margin
FROM Production.Product PD
JOIN Production.ProductSubcategory PS ON PD.ProductSubcategoryID = PS.ProductSubcategoryID
JOIN Production.ProductCategory PC ON PS.ProductCategoryID = PC.ProductCategoryID
WHERE PD.ListPrice > 0
GROUP BY PC.Name
ORDER BY AVG_Profit_Margin DESC
;


--	15)	Way of shipping, and relation of customers purchasing decision

SELECT SM.Name AS Shipping_Method, COUNT(SOH.SalesOrderID) AS Order_Count, AVG(DATEDIFF(day, SOH.OrderDate, SOH.ShipDate)) AS AVG_Delivery_Time,
		AVG(SOH.TotalDue) AS AVG_Order_Value
FROM Sales.SalesOrderHeader SOH
JOIN Purchasing.ShipMethod SM ON SOH.ShipMethodID = SM.ShipMethodID
WHERE SOH.ShipMethodID IS NOT NULL
GROUP BY SM.Name
ORDER BY Order_Count DESC
;

--	16)	Any product and trend line for the last 5 years

SELECT YEAR(SOH.OrderDate) AS Year, MONTH(SOH.OrderDate) AS Month, SUM(SOD.LineTotal) AS Total_Sales
FROM Sales.SalesOrderHeader SOH
JOIN Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN Production.Product PD ON SOD.ProductID = PD.ProductID
WHERE PD.Name = 'Water Bottle - 30 oz.'
GROUP BY YEAR(SOH.OrderDate), MONTH(SOH.OrderDate)
ORDER BY Year, Month
;

--	17)	Demographics and relation with purchasing behavior

SELECT A.City, SP.Name, SP.CountryRegionCode, SP.StateProvinceCode, COUNT(SOH.SalesOrderID) AS Order_Count, AVG(soh.TotalDue) AS AVG_Order_Value
FROM Sales.SalesOrderHeader SOH
JOIN Sales.Customer C ON SOH.CustomerID = C.CustomerID
LEFT JOIN Person.Person P ON C.PersonID = P.BusinessEntityID
LEFT JOIN Person.BusinessEntityAddress BEA ON P.BusinessEntityID = BEA.BusinessEntityID
LEFT JOIN Person.Address A ON BEA.AddressID = A.AddressID
LEFT JOIN Person.StateProvince SP ON A.StateProvinceID = SP.StateProvinceID
WHERE A.City IS NOT NULL
GROUP BY A.City, SP.Name, SP.CountryRegionCode, SP.StateProvinceCode
ORDER BY Order_Count DESC
;

-- 
SELECT st.Name AS TerritoryName, SUM(sod.LineTotal) AS TotalSpent
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
GROUP BY st.Name
ORDER BY TotalSpent DESC;

--

SELECT AVG(CustomerRevenue.TotalSpent) AS AvgRevenuePerCustomer
FROM (
    SELECT soh.CustomerID, SUM(sod.LineTotal) AS TotalSpent
    FROM Sales.SalesOrderHeader soh
    JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
    GROUP BY soh.CustomerID
) AS CustomerRevenue;


-- 
SELECT TOP 10 p.Name AS ProductName, SUM(sod.OrderQty) AS TotalQuantitySold
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY TotalQuantitySold DESC;


-- 
SELECT p.Name AS ProductName, p.ListPrice AS UnitPrice, SUM(sod.OrderQty) AS TotalQuantitySold
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY p.Name, p.ListPrice
ORDER BY UnitPrice;

-- 
SELECT TOP 3 sp.BusinessEntityID AS SalespersonID, p.FirstName, p.LastName, SUM(sod.LineTotal) AS TotalRevenue
FROM Sales.SalesPerson sp 0
JOIN HumanResources.Employee e ON sp.BusinessEntityID = e.BusinessEntityID
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
JOIN Sales.SalesOrderHeader soh ON sp.BusinessEntityID = soh.SalesPersonID
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
GROUP BY sp.BusinessEntityID, p.FirstName, p.LastName
ORDER BY TotalRevenue DESC
;

-- 
SELECT st.Name AS TerritoryName, AVG(sod.LineTotal) AS AvgRevenuePerTerritory
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
GROUP BY st.Name
ORDER BY AvgRevenuePerTerritory DESC;

--

SELECT st.Name AS TerritoryName, SUM(sod.LineTotal) AS TotalSales
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
GROUP BY st.Name
ORDER BY TotalSales DESC;

-- 
SELECT st.Name AS TerritoryName, SUM(sod.LineTotal) AS TotalSales
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Sales.SalesTerritory st ON soh.TerritoryID = st.TerritoryID
GROUP BY st.Name
ORDER BY TotalSales ASC; -- Order by ascending to find underperforming territories
