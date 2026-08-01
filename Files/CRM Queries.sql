/*
===============================================================================
B2B Sales Pipeline - Database Setup Script
===============================================================================
Data Source: Maven Analytics - CRM Sales Opportunities
Instructions:
1. Create a database named 'CRM_Sales_Opportunities'.
2. Load the CSV files into staging tables using either:
   a) SQL Server Management Studio (SSMS) Import Wizard (Right-click DB -> Tasks -> Import Flat File)
   b) The BULK INSERT statements below (Update the file paths to your local directory).
===============================================================================
*/

create database CRM_Sales_Opportunities

use CRM_Sales_Opportunities

--Creation of tables based on downloaded csv files
create table dim_accounts(
	account nvarchar(100),
	sector nvarchar(100),
	year_established date,
	revenue float,
	employees int,
	office_location nvarchar(100),
	subsidiary_of nvarchar(100))


create table fact_sales_pipeline(
	opportunity_id nvarchar(100),
	sales_agent nvarchar(100),
	product nvarchar(100),
	account nvarchar(100),
	deal_stage nvarchar(100),
	engage_date date,
	close_date date,
	close_value int
)


create table dim_products(
	product nvarchar(100),
	series nvarchar(100),
	sales_price int
)


create table dim_sales_teams(
	sales_agent nvarchar(100) primary key,
	manager nvarchar(100),
	regional_office nvarchar(100)
)


--Creation of a dedicated table for dates
CREATE TABLE dim_date (
    date_key          INT NOT NULL PRIMARY KEY,
    full_date         DATE NOT NULL UNIQUE,    
    year_number       INT NOT NULL,            
    quarter_number    INT NOT NULL,            
    quarter_name      VARCHAR(10) NOT NULL,    
    month_number      INT NOT NULL,             
    month_name        VARCHAR(20) NOT NULL,    
    month_name_short  VARCHAR(3) NOT NULL,      
    week_of_year      INT NOT NULL,             
    day_of_month      INT NOT NULL,             
    day_of_week       INT NOT NULL,             
    day_name          VARCHAR(20) NOT NULL,     
    is_weekend        BIT NOT NULL              
)

SET LANGUAGE English;

DECLARE @StartDate DATE = '2016-01-01';
DECLARE @EndDate   DATE = '2026-12-31';

WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO dim_date (
        date_key,
        full_date,
        year_number,
        quarter_number,
        quarter_name,
        month_number,
        month_name,
        month_name_short,
        week_of_year,
        day_of_month,
        day_of_week,
        day_name,
        is_weekend
    )
    VALUES (
        CAST(CONVERT(VARCHAR(8), @StartDate, 112) AS INT), 
        @StartDate,
        YEAR(@StartDate),
        DATEPART(QUARTER, @StartDate),
        'Q' + CAST(DATEPART(QUARTER, @StartDate) AS VARCHAR(1)),
        MONTH(@StartDate),
        DATENAME(MONTH, @StartDate),
        UPPER(LEFT(DATENAME(MONTH, @StartDate), 3)),
        DATEPART(WEEK, @StartDate),
        DAY(@StartDate),
        DATEPART(WEEKDAY, @StartDate),
        DATENAME(WEEKDAY, @StartDate),
        CASE WHEN DATEPART(WEEKDAY, @StartDate) IN (1, 7) THEN 1 ELSE 0 END
    );

    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END;



--Cleaning of columns to be used as primary key and foreing keys to stablish relationships between the tables
SELECT DISTINCT f.product 
FROM fact_sales_pipeline f
LEFT JOIN dim_products d ON f.product = d.product
WHERE d.product IS NULL;

UPDATE fact_sales_pipeline SET product = TRIM(product);
UPDATE dim_products SET product = TRIM(product);

UPDATE fact_sales_pipeline 
SET product = NULL 
WHERE product = '' OR product = 'N/A';

INSERT INTO dim_products (product)
SELECT DISTINCT f.product
FROM fact_sales_pipeline f
LEFT JOIN dim_products d ON f.product = d.product
WHERE d.product IS NULL AND f.product IS NOT NULL;


--Altering all created tables to define primary and foreing keys and stablish connections between tables
ALTER TABLE dim_accounts
ALTER COLUMN account nvarchar(100) NOT NULL

ALTER TABLE dim_accounts
ADD CONSTRAINT PK_dim_accounts_account PRIMARY KEY (account);


ALTER TABLE fact_sales_pipeline
ALTER COLUMN opportunity_id nvarchar(100) NOT NULL

ALTER TABLE fact_sales_pipeline
ADD CONSTRAINT FK_sales_pipeline_sales_agent FOREIGN KEY (sales_agent) REFERENCES dim_sales_teams(sales_agent),
CONSTRAINT FK_sales_pipeline_product FOREIGN KEY (product) REFERENCES dim_products(product),
CONSTRAINT FK_sales_pipeline_account FOREIGN KEY (account) REFERENCES dim_accounts(account)


ALTER TABLE dim_products
ALTER COLUMN product nvarchar(100) NOT NULL

ALTER TABLE dim_products
ADD CONSTRAINT PK_dim_products_product PRIMARY KEY (product);


ALTER TABLE fact_sales_pipeline
ADD CONSTRAINT FK_sales_pipeline_engage_date FOREIGN KEY (engage_date) REFERENCES dim_date(full_date),
    CONSTRAINT FK_sales_pipeline_close_date FOREIGN KEY (close_date) REFERENCES dim_date(full_date);


--Bulk insert of data, use it to bulk insert from files: account, products, sales_pipeline, sales_teams
BULK INSERT dim_sales_teams
FROM 'C:\YOUR_LOCAL_PATH\sales_pipeline.csv'
WITH (
    FORMAT = 'CSV',              
    FIRSTROW = 2,                 
    FIELDTERMINATOR = ',',        
    ROWTERMINATOR = '\n',        
    TABLOCK                   
)

--Creation of Views for PBI
CREATE OR ALTER VIEW vw_fact_sales_pipeline AS
SELECT 
    opportunity_id,
    sales_agent,
    product,
    account,
    deal_stage,
    engage_date,
    close_date,
    ISNULL(close_value, 0) AS close_value,
   
    CASE 
        WHEN deal_stage IN ('Won', 'Lost') AND engage_date IS NOT NULL AND close_date IS NOT NULL 
        THEN DATEDIFF(DAY, engage_date, close_date)
        ELSE NULL
    END AS sales_cycle_days,

    CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END AS is_won,
    CASE WHEN deal_stage = 'Lost' THEN 1 ELSE 0 END AS is_lost,
    CASE WHEN deal_stage IN ('Engaging', 'Prospecting') THEN 1 ELSE 0 END AS is_open

FROM fact_sales_pipeline;
GO


CREATE OR ALTER VIEW vw_dim_accounts AS
SELECT 
    account,
    sector,
    year_established,
    revenue,
    employees,
    office_location,
    
    CASE 
        WHEN employees < 50 THEN 'Small'
        WHEN employees BETWEEN 50 AND 500 THEN 'Mid-Market'
        WHEN employees > 500 THEN 'Enterprise'
        ELSE 'Uncategorized'
    END AS company_size_category

FROM dim_accounts;
GO


CREATE OR ALTER VIEW vw_kpi_sales_summary AS
SELECT 
    f.sales_agent,
    st.manager,
    st.regional_office,
    f.product,
    
    COUNT(f.opportunity_id) AS total_opportunities,
    SUM(f.is_won) AS won_deals,
    SUM(f.is_lost) AS lost_deals,
    SUM(f.is_open) AS open_deals,
    
    SUM(f.close_value) AS total_revenue,
    AVG(CASE WHEN f.deal_stage = 'Won' THEN f.close_value END) AS avg_ticket_size,
    
    ROUND(
        (CAST(SUM(f.is_won) AS FLOAT) / 
         NULLIF(SUM(f.is_won) + SUM(f.is_lost), 0)) * 100, 2
    ) AS win_rate_percentage,
    
    AVG(f.sales_cycle_days) AS avg_days_to_close

FROM vw_fact_sales_pipeline f
LEFT JOIN dim_sales_teams st ON f.sales_agent = st.sales_agent
GROUP BY 
    f.sales_agent, 
    st.manager, 
    st.regional_office, 
    f.product;
GO

--Verifying tha views do work
SELECT TOP 10 * FROM vw_fact_sales_pipeline;
SELECT TOP 10 * FROM vw_dim_accounts;
SELECT TOP 10 * FROM vw_kpi_sales_summary;
