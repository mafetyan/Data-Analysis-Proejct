# -*- coding: utf-8 -*-
"""
Created on Sat Oct 19 18:15:03 2024

@author: fitya
"""
# Import Libraries
import pyodbc
import pandas as pd


""" ---- Connection With SQL ---- """
# Begin Connection
cnxn_str = ("Driver={ODBC Driver 17 for SQL Server};"
            "Server=DESKTOP-CK5GPC9\MSSQLSERVER01;"
            "Database=AdventureWorks2019;"
            "Trusted_Connection=yes;")

cnxn = pyodbc.connect(cnxn_str)

# Import Tables 
# pd.read_sql("", cnxn)
SalesPerson = pd.read_sql("Select * From Sales.Salesperson", cnxn)
ProductCategory = pd.read_sql("Select * From Production.ProductCategory", cnxn)
ProductSubcategory = pd.read_sql("Select * From Production.ProductSubcategory", cnxn)
Product = pd.read_sql("Select * From Production.Product", cnxn)
SalesOrderDetail = pd.read_sql("Select * From Sales.SalesOrderDetail", cnxn)
SalesOrderHeader = pd.read_sql("Select * From Sales.SalesOrderHeader", cnxn)
SalesTerritory = pd.read_sql("Select * From Sales.SalesTerritory", cnxn)
Person = pd.read_sql("Select * From Person.Person", cnxn)

""" ---- Data Cleaning ---- """
# Check Missing Values
SalesOrderDetail.isnull().sum()
SalesOrderHeader.isnull().sum()
Product.isnull().sum()
ProductCategory.isnull().sum()
ProductSubcategory.isnull().sum()
SalesTerritory.isnull().sum()
Person.isnull().sum()
SalesPerson.isnull().sum()

# Check Data types
SalesOrderDetail.info()
SalesOrderHeader.info()
Product.info()
ProductCategory.info()
ProductSubcategory.info()
SalesTerritory.info()
Person.info()
SalesPerson.info()

# Drop Columns
del SalesOrderDetail['CarrierTrackingNumber']
del SalesOrderDetail['rowguid']
del SalesOrderDetail['ModifiedDate']
del SalesOrderHeader['rowguid']
del SalesOrderHeader['ModifiedDate']
del Product['rowguid']
del Product['ModifiedDate']
del ProductCategory['rowguid']
del ProductCategory['ModifiedDate']
del ProductSubcategory['rowguid']
del ProductSubcategory['ModifiedDate']
del SalesTerritory['rowguid']
del SalesTerritory['ModifiedDate']
del Person['rowguid']
del Person['ModifiedDate']
del SalesPerson['rowguid']
del SalesPerson['ModifiedDate']
del SalesOrderHeader['Comment']
del Product['DiscontinuedDate']
SalesOrderHeader.drop(columns = ['CreditCardID','CreditCardApprovalCode'], inplace = True)
Product.drop(columns = ['Color','Size','SizeUnitMeasureCode','WeightUnitMeasureCode','Weight'], inplace = True)


# Standarizing Text Fields


""" ---- Data Transformation ---- """
# New Columns
Product['Profit'] = Product.ListPrice - Product.StandardCost
Product['Profit Margin'] = (Product.Profit/Product.ListPrice)*100
SalesOrderHeader['DeliveryTime'] = (SalesOrderHeader['ShipDate'] - SalesOrderHeader['OrderDate']).dt.days


""" ---- Check Outliers ---- """
Product.boxplot(column = ['ListPrice'])

""" ---- Data Validation ---- """
SalesOrderDetail = SalesOrderDetail[SalesOrderDetail['OrderQty']>0]
SalesOrderDetail = SalesOrderDetail[SalesOrderDetail['UnitPrice']>0]

""" ---- Exporting ---- """
SalesOrderDetail.to_csv('D:\Data Analyst\Final Project\Cleaned Data\SalesOrderDetail.csv', index = False)
SalesOrderHeader.to_csv('D:\Data Analyst\Final Project\Cleaned Data\SalesOrderHeader.csv', index = False)
Product.to_csv('D:\Data Analyst\Final Project\Cleaned Data\Product.csv', index = False)
ProductCategory.to_csv('D:\Data Analyst\Final Project\Cleaned Data\ProductCategory.csv', index = False)
ProductSubcategory.to_csv('D:\Data Analyst\Final Project\Cleaned Data\ProductSubcategory.csv', index = False)
SalesTerritory.to_csv('D:\Data Analyst\Final Project\Cleaned Data\SalesTerritory.csv', index = False)
Person.to_csv('D:\Data Analyst\Final Project\Cleaned Data\Person.csv', index = False)
SalesPerson.to_csv('D:\Data Analyst\Final Project\Cleaned Data\SalesPerson.csv', index = False)


# forecasting


sales_data = pd.read_sql("Select OrderDate,TotalDue From Sales.SalesOrderHeader", cnxn)
sales_data['OrderDate'] = pd.to_datetime(sales_data['OrderDate'])
print(sales_data.head())
sales_data['Year']=sales_data['OrderDate'].dt.year
sales_data['month']=sales_data['OrderDate'].dt.month

monthly_sales = sales_data.groupby([sales_data['Year'], sales_data['month']])['TotalDue'].sum().reset_index()
monthly_sales['Time'] = monthly_sales['Year'] * 12 + monthly_sales['month']
print(monthly_sales.head())

from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
import matplotlib.pyplot as plt

X = monthly_sales[['Time']]
y = monthly_sales['TotalDue']
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, shuffle=False)

model = LinearRegression()
model.fit(X_train, y_train)

future_time = pd.DataFrame({'Time': [X_train['Time'].max() + i for i in range(1, 4)]})
future_sales = model.predict(future_time)

plt.plot(monthly_sales['Time'], monthly_sales['TotalDue'], label='Historical Sales')
plt.plot(future_time['Time'], future_sales, label='Forecasted Sales', linestyle='--', marker='o')
plt.xlabel('Time (Year-Month)')
plt.ylabel('Total Sales')
plt.legend()
plt.title('Sales Forecast for the Next 3 Months')
plt.show()


# Corrolation on sales order header
corr_Data = pd.read_sql("Select  OrderDate, TotalDue, TaxAmt, Freight, SubTotal From Sales.SalesOrderHeader", cnxn)
import seaborn as sns

correlation_matrix = corr_Data[['TotalDue', 'TaxAmt', 'Freight', 'SubTotal']].corr()

# Visualize the correlation matrix using a heatmap
plt.figure(figsize=(8, 6))
sns.heatmap(correlation_matrix, annot=True, cmap='coolwarm')
plt.title('Correlation Matrix: SalesOrderHeader')
plt.show()